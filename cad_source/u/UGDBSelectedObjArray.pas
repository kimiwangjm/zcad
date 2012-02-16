{
*****************************************************************************
*                                                                           *
*  This file is part of the ZCAD                                            *
*                                                                           *
*  See the file COPYING.modifiedLGPL.txt, included in this distribution,    *
*  for details about the copyright.                                         *
*                                                                           *
*  This program is distributed in the hope that it will be useful,          *
*  but WITHOUT ANY WARRANTY; without even the implied warranty of           *
*  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.                     *
*                                                                           *
*****************************************************************************
}
{
@author(Andrey Zubarev <zamtmn@yandex.ru>) 
}

unit UGDBSelectedObjArray;
{$INCLUDE def.inc}
interface
uses {GDBWithLocalCS,}GDBWithMatrix,GDBEntity,UGDBControlPointArray,UGDBOpenArrayOfData{, oglwindowdef},sysutils,gdbase, geometry,
     gl,
     gdbasetypes{,varmandef,gdbobjectsconstdef},memman,OGLSpecFunc;
type
{Export+}
PSelectedObjDesc=^SelectedObjDesc;
SelectedObjDesc=record
                      objaddr:PGDBObjEntity;
                      pcontrolpoint:PGDBControlPointArray;
                      ptempobj:PGDBObjEntity;
                end;
GDBSelectedObjArray=object(GDBOpenArrayOfData)
                          SelectedCount:GDBInteger;
                          constructor init({$IFDEF DEBUGBUILD}ErrGuid:pansichar;{$ENDIF}m:GDBInteger);

                          function addobject(objnum:PGDBObjEntity):pselectedobjdesc;virtual;
                          procedure clearallobjects;virtual;
                          procedure remappoints;virtual;
                          procedure drawpoint;virtual;
                          procedure drawobject(var DC:TDrawContext{infrustumactualy:TActulity;subrender:GDBInteger});virtual;
                          function getnearesttomouse:tcontrolpointdist;virtual;
                          procedure selectcurrentcontrolpoint(key:GDBByte);virtual;
                          procedure RenderFeedBack;virtual;
                          //destructor done;virtual;
                          procedure modifyobj(dist,wc:gdbvertex;save:GDBBoolean;pconobj:pgdbobjEntity);virtual;
                          procedure freeclones;
                          procedure Transform(dispmatr:DMatrix4D);
                          procedure SetRotate(minusd,plusd,rm:DMatrix4D;x,y,z:GDBVertex);
                          procedure SetRotateObj(minusd,plusd,rm:DMatrix4D;x,y,z:GDBVertex);
                          procedure TransformObj(dispmatr:DMatrix4D);

                          procedure drawobj(var DC:TDrawContext{infrustumactualy:TActulity;subrender:GDBInteger});virtual;
                          procedure freeelement(p:GDBPointer);virtual;
                          function calcvisible(frustum:cliparray;infrustumactualy:TActulity;visibleactualy:TActulity):GDBBoolean;virtual;
                          procedure resprojparam;
                    end;
{EXPORT-}
implementation
uses {oglwindow,}ugdbdescriptor,log;
procedure GDBSelectedObjArray.resprojparam;
var tdesc:pselectedobjdesc;
    i:GDBInteger;
begin
  if count<>0 then
  begin
       tdesc:=parray;
       for i:=0 to count-1 do
       begin
            //dec(tdesc^.objaddr^.vp.LastCameraPos);
            tdesc^.objaddr^.Renderfeedback;
            inc(tdesc);
       end;
  end;
end;
procedure GDBSelectedObjArray.freeelement;
begin
  if PSelectedObjDesc(p).pcontrolpoint<>nil then
                                                begin
                                                     PSelectedObjDesc(p).pcontrolpoint^.FreeAndDone;
                                                     gdbfreemem(GDBPointer(PSelectedObjDesc(p).pcontrolpoint));
                                                end;
  if PSelectedObjDesc(p).ptempobj<>nil then
                                           begin
                                                PSelectedObjDesc(p).ptempobj^.done;
                                                gdbfreemem(GDBPointer(PSelectedObjDesc(p).ptempobj));
                                           end;
  //PGDBObjBlockdef(p).Entities.ClearAndDone;
end;
constructor GDBSelectedObjArray.init;
begin
  {Count := 0;
  Max := m;
  Size := sizeof(selectedobjdesc);
  GDBGetMem(PArray, size * max);}
  inherited init({$IFDEF DEBUGBUILD}ErrGuid,{$ENDIF}m,sizeof(selectedobjdesc));
end;
function GDBSelectedObjArray.addobject;
var tdesc:pselectedobjdesc;
    i:GDBInteger;
begin
  result:=nil;
  if PARRAY=nil then
                    createarray;
  tdesc:=parray;
  if count<>0 then
  begin
       for i:=0 to count-1 do
       begin
            if tdesc^.objaddr=objnum then
            begin
                 result:=tdesc;
                 exit;
            end;
            inc(tdesc);
       end;
  end;
  if count=max then exit;
  result:=tdesc;
  inc(count);
  tdesc^.objaddr:=objnum;
  tdesc^.pcontrolpoint:=nil;
  tdesc^.ptempobj:=nil;
end;
procedure GDBSelectedObjArray.clearallobjects;
var tdesc:pselectedobjdesc;
    i:GDBInteger;
begin
  tdesc:=parray;
  if count<>0 then
  begin
       for i:=0 to count-1 do
       begin
            if tdesc^.pcontrolpoint<>nil then
            begin
                tdesc^.pcontrolpoint^.done;
                GDBFreeMem(GDBPointer(tdesc^.pcontrolpoint));
            end;
            if tdesc^.ptempobj<>nil then
            begin
                 tdesc^.ptempobj^.done;
                 GDBFreeMem(GDBPointer(tdesc^.ptempobj));
            end;
            inc(tdesc);
       end;
  end;
  count:=0;
end;
procedure GDBSelectedObjArray.drawpoint;
var tdesc:pselectedobjdesc;
    i:GDBInteger;
begin
  if count<>0 then
  begin
       tdesc:=parray;
       oglsm.myglpointsize(10);
       oglsm.myglbegin(gl_points);
       for i:=0 to count-1 do
       begin
            if tdesc^.pcontrolpoint<>nil then
            begin
                 tdesc^.pcontrolpoint^.draw;
            end;
            inc(tdesc);
       end;
       oglsm.myglend;
       oglsm.myglpointsize(1);
  end;
end;
procedure GDBSelectedObjArray.RenderFeedBack;
var tdesc:pselectedobjdesc;
    i:GDBInteger;
begin
  if count<>0 then
  begin
       tdesc:=parray;
       for i:=0 to count-1 do
       begin
            if tdesc^.objaddr<>nil then
            begin
                 tdesc^.objaddr^.RenderFeedbackIFNeed;
            end;
            inc(tdesc);
       end;
  end;
end;procedure GDBSelectedObjArray.drawobject;
var tdesc:pselectedobjdesc;
    i:GDBInteger;
begin
  if count<>0 then
  begin
       tdesc:=parray;
       for i:=0 to count-1 do
       begin
            if tdesc^.objaddr<>nil then
            begin
                 tdesc^.objaddr^.DrawWithOutAttrib({infrustumactualy,}dc{subrender}); //DrawGeometry(tdesc^.objaddr^.CalculateLineWeight);
            end;
            inc(tdesc);
       end;
  end;
end;
procedure GDBSelectedObjArray.remappoints;
var tdesc:pselectedobjdesc;
    i:GDBInteger;
begin
  if count<>0 then
  begin
       tdesc:=parray;
       for i:=0 to count-1 do
       begin
            if tdesc^.pcontrolpoint<>nil then
            begin
                 tdesc^.objaddr^.remapcontrolpoints(tdesc^.pcontrolpoint);
            end;
            inc(tdesc);
       end;
  end;
end;
function GDBSelectedObjArray.getnearesttomouse;
var i: GDBInteger;
//  d: GDBDouble;
  td:tcontrolpointdist;
  tdesc:pselectedobjdesc;
begin
  td.pcontrolpoint := nil;
  td.disttomouse:=9999;
  if count > 0 then
  begin
    tdesc:=parray;
    for i := 0 to count - 1 do
    begin
      if tdesc^.pcontrolpoint<>nil then tdesc^.pcontrolpoint^.getnearesttomouse(td);
      inc(tdesc);
    end;
  end;
  result:=td;
end;

(*procedure processobject(pobj:PGDBObjEntity;minusd,plusd,rm:DMatrix4D;x,y,z:GDBVertex);
var i: GDBInteger;
  m,m2,oplus,ominus:DMatrix4D;
  tv,P_insert_in_OCS,P_insert_in_WCS:gdbvertex;
begin
  pobj^.Transform(minusd);

  //1) Делаем M единичной
  m:=onematrix;
  //2) Сдвигаем в начало координат. Для этого выдираем из матрицы объекта элементы
  //отвечающие за смещение, и строим на них матрицу сдвига в начало координат - minus
  //и вторую, для сдвига обратно - plus.Умножаем М на матрицу сдвига в начало системы
  m:=PGDBObjWithMatrix(pobj)^.ObjMatrix;
  P_insert_in_OCS:=PGDBVertex(@m[3])^;
  ominus:=geometry.CreateTranslationMatrix(geometry.MinusVertex(P_insert_in_OCS));
  oplus:=geometry.CreateTranslationMatrix(P_insert_in_OCS);
  m:=geometry.MatrixMultiply(m,ominus);

  //3) Выравниваем оси по глобальной СКО. Берем матрицу из объекта Mobj и удаляем
  //у нее элементы сдвига, потом инвертируем (или транспонируем, для матриц
  //вращения это одно и то же). M = M*Mobj_inv
  m2:=PGDBObjWithMatrix(pobj)^.ObjMatrix;
  PGDBVertex(@m2[3])^:=nulvertex;
  matrixinvert(m2);
  m:=geometry.MatrixMultiply(m,m2);

  //4) Выравниваем оси по СКО приемника. Выдираем матрицу из приемника - Mdest,
  //обнуляем ей элементы сдвига и умножаем на M: M = M*Mdest
  m:=geometry.MatrixMultiply(m,rm);

  //5) Двигаем объект обратно. M = M*plus
  m:=geometry.MatrixMultiply(m,oplus);


  //6) Двигаем объект в точку крепежа на приемнике. Составляем матрицу сдвига
  //Мpick на основе вектора Vpick - Vobj (точка крепежа минус положение объекта).
  //M = M*Mpck.
  //7) Двигаем объект с учетом смещения точки крепежа исходного объекта внутри
  //его локальной системы координат. Ну думаю сообразишь.

  pobj^.Transform(m);

  pobj^.Transform(plusd);
  PGDBObjWithMatrix(pobj)^.ReCalcFromObjMatrix;
  PGDBObjWithMatrix(pobj)^.Format;
end;

*)
procedure processobject(pobj:PGDBObjEntity;minusd,plusd,rm:DMatrix4D;x,y,z:GDBVertex);
var i: GDBInteger;
  m,oplus,ominus:DMatrix4D;
  tv,P_insert_in_OCS,P_insert_in_WCS:gdbvertex;
begin
  pobj^.Transform(minusd);

  m:=PGDBObjWithMatrix(pobj)^.ObjMatrix;
  P_insert_in_OCS:=PGDBVertex(@m[3])^;
  PGDBVertex(@m[3])^:=nulvertex;
  matrixinvert(m);
  P_insert_in_WCS:=VectorTransform3D(P_insert_in_OCS,m);
  m:=onematrix;
  PGDBVertex(@m[3])^:=P_insert_in_wCS;
  PGDBObjWithMatrix(pobj)^.ObjMatrix:=m;
  pobj^.Transform(rm);

  pobj^.Transform(plusd);
  PGDBObjWithMatrix(pobj)^.ReCalcFromObjMatrix;
  PGDBObjWithMatrix(pobj)^.Format;
end;

(*procedure processobject(pobj:PGDBObjEntity;minusd,plusd,rm:DMatrix4D;x,y,z:GDBVertex);
var i: GDBInteger;
//  d: GDBDouble;
//  td:tcontrolpointdist;
  m,m2,oplus,ominus:DMatrix4D;
  tv:gdbvertex;
  l1,l2:GDBObj2dprop;
{
pobj^.Transform(minusd);
m:=PGDBObjWithMatrix(pobj)^.ObjMatrix;
PGDBVertex(@m[3])^:=nulvertex;
matrixinvert(m);
pobj^.Transform(m);
pobj^.Transform(rm);
pobj^.Transform(plusd);
PGDBObjWithMatrix(pobj)^.ReCalcFromObjMatrix;
PGDBObjWithMatrix(pobj)^.Format;
}
begin
  l1:=PGDBObjWithLocalCS(pobj)^.Local;
  m:=PGDBObjWithMatrix(pobj)^.ObjMatrix;
  pobj^.Transform({minusd}onematrix);
  l2:=PGDBObjWithLocalCS(pobj)^.Local;
  //m:=PGDBObjWithMatrix(pobj)^.ObjMatrix;
  //PGDBVertex(@m[3])^:=nulvertex;
  //matrixinvert(m);
  //pobj^.Transform(m);
  //pobj^.Transform(rm);
  pobj^.Transform({plusd}onematrix);
  m2:=PGDBObjWithMatrix(pobj)^.ObjMatrix;
  l2:=PGDBObjWithLocalCS(pobj)^.Local;
  //PGDBObjWithMatrix(pobj)^.ReCalcFromObjMatrix;
  m:=PGDBObjWithMatrix(pobj)^.ObjMatrix;
  PGDBObjWithMatrix(pobj)^.Format;
  m2:=PGDBObjWithMatrix(pobj)^.ObjMatrix;
  {pobj^.Transform(minusd);
  m:=PGDBObjWithMatrix(pobj)^.ObjMatrix;
  tv:=vectortransform3d(nulvertex,m);
  oplus:=geometry.CreateTranslationMatrix(tv);
  ominus:=geometry.CreateTranslationMatrix(createvertex(-tv.x,-tv.y,-tv.z));
  PGDBVertex(@m[3])^:=nulvertex;
  matrixinvert(m);
  PGDBObjWithMatrix(pobj)^.ObjMatrix:=onematrix;
  //pobj^.Transform(m);
  pobj^.Transform(oplus);
  pobj^.Transform(rm);
  pobj^.Transform(plusd);
  PGDBObjWithMatrix(pobj)^.ReCalcFromObjMatrix;
  PGDBObjWithMatrix(pobj)^.Format;}
end;
*)
procedure GDBSelectedObjArray.SetRotate(minusd,plusd,rm:DMatrix4D;x,y,z:GDBVertex);
var i: GDBInteger;
//  d: GDBDouble;
//  td:tcontrolpointdist;
  tdesc:pselectedobjdesc;
  m,oplus:DMatrix4D;
  tv:gdbvertex;
begin
  if count > 0 then
  begin
    tdesc:=parray;
    for i := 0 to count - 1 do
    begin
      if tdesc^.pcontrolpoint<>nil then
        if tdesc^.pcontrolpoint^.SelectedCount<>0 then
        begin
             processobject(tdesc^.ptempobj,minusd,plusd,rm,x,y,z);
        end;
      inc(tdesc);
    end;
  end;
  {if save then
              gdb.GetCurrentROOT.FormatAfterEdit;}
end;
procedure GDBSelectedObjArray.SetRotateObj(minusd,plusd,rm:DMatrix4D;x,y,z:GDBVertex);
var i: GDBInteger;
//  d: GDBDouble;
//  td:tcontrolpointdist;
  tdesc:pselectedobjdesc;
  m,tempm,oplus,ominus:DMatrix4D;
  tv:gdbvertex;
begin
  if count > 0 then
  begin
    tdesc:=parray;
    for i := 0 to count - 1 do
    begin
      if tdesc^.pcontrolpoint<>nil then
        //if tdesc^.pcontrolpoint^.SelectedCount<>0 then
        begin
          processobject(tdesc^.objaddr,minusd,plusd,rm,x,y,z);
          {tdesc^.objaddr^.Transform(minusd);
          m:=PGDBObjWithMatrix(tdesc^.objaddr)^.ObjMatrix;
          PGDBVertex(@m[3])^:=nulvertex;
          matrixinvert(m);
          tdesc^.objaddr^.Transform(m);
          tdesc^.objaddr^.Transform(rm);
          tdesc^.objaddr^.Transform(plusd);
          PGDBObjWithMatrix(tdesc^.objaddr)^.ReCalcFromObjMatrix;
          PGDBObjWithMatrix(tdesc^.objaddr)^.Format;}
        end;
      inc(tdesc);
    end;
  end;
  {if save then
              gdb.GetCurrentROOT.FormatAfterEdit;}
end;

procedure GDBSelectedObjArray.Transform(dispmatr:DMatrix4D);
var i: GDBInteger;
//  d: GDBDouble;
//  td:tcontrolpointdist;
  tdesc:pselectedobjdesc;
begin
  if count > 0 then
  begin
    tdesc:=parray;
    for i := 0 to count - 1 do
    begin
      if tdesc^.pcontrolpoint<>nil then
        if tdesc^.pcontrolpoint^.SelectedCount<>0 then
        begin
             tdesc^.ptempobj^.Transform(dispmatr);
             tdesc^.ptempobj^.Format;

             //tdesc^.objaddr^.Transform{At}(dispmatr);
             //tdesc^.objaddr^.Format;
             //gdb.rtmodify(tdesc^.objaddr,tdesc,dist,wc,save);
        end;
      inc(tdesc);
    end;
  end;
  {if save then
              gdb.GetCurrentROOT.FormatAfterEdit;}
end;
procedure GDBSelectedObjArray.TransformObj(dispmatr:DMatrix4D);
var i: GDBInteger;
  tdesc:pselectedobjdesc;
begin
  if count > 0 then
  begin
    tdesc:=parray;
    for i := 0 to count - 1 do
    begin
      if tdesc^.pcontrolpoint<>nil then
        //if tdesc^.pcontrolpoint^.SelectedCount<>0 then
        begin
             tdesc^.objaddr^.Transform(dispmatr);
             tdesc^.objaddr^.Format;

             //tdesc^.objaddr^.Transform{At}(dispmatr);
             //tdesc^.objaddr^.Format;
             //gdb.rtmodify(tdesc^.objaddr,tdesc,dist,wc,save);
        end;
      inc(tdesc);
    end;
  end;
  {if save then
              gdb.GetCurrentROOT.FormatAfterEdit;}
end;

procedure GDBSelectedObjArray.modifyobj;
var i: GDBInteger;
//  d: GDBDouble;
//  td:tcontrolpointdist;
  tdesc:pselectedobjdesc;
begin
  if count > 0 then
  begin
    tdesc:=parray;
    for i := 0 to count - 1 do
    begin
      if tdesc^.pcontrolpoint<>nil then
        if tdesc^.pcontrolpoint^.SelectedCount<>0 then
        begin
           {tdesc^.objaddr^}gdb.rtmodify(tdesc^.objaddr,tdesc,dist,wc,save);
        end;
      inc(tdesc);
    end;
  end;
  if save then
              gdb.GetCurrentROOT.FormatAfterEdit;

end;
procedure GDBSelectedObjArray.freeclones;
var i: GDBInteger;
//  d: GDBDouble;
//  td:tcontrolpointdist;
  tdesc:pselectedobjdesc;
begin
  if count > 0 then
  begin
    tdesc:=parray;
    for i := 0 to count - 1 do
    begin
      if tdesc^.ptempobj<>nil then
        begin
          tdesc^.ptempobj^.done;
          GDBFreeMem(GDBPointer(tdesc^.ptempobj));
          tdesc^.ptempobj:=nil;
        end;
      inc(tdesc);
    end;
  end;
end;

function GDBSelectedObjArray.calcvisible;
{var
  p:pGDBObjEntity;
  q:GDBBoolean;}
var i: GDBInteger;
//  d: GDBDouble;
//  td:tcontrolpointdist;
  tdesc:pselectedobjdesc;
begin
  {result:=false;
  p:=beginiterate;
  if p<>nil then
  repeat
       q:=p^.calcvisible;
       result:=result or q;
       p:=iterate;
  until p=nil;}
  if count > 0 then
  begin
    tdesc:=parray;
    for i := 0 to count - 1 do
    begin
      if tdesc^.ptempobj<>nil then
                                  tdesc^.ptempobj^.calcvisible(frustum,infrustumactualy,visibleactualy);
      inc(tdesc);
    end;
  end;

end;
procedure GDBSelectedObjArray.drawobj;
var i: GDBInteger;
//  d: GDBDouble;
//  td:tcontrolpointdist;
  tdesc:pselectedobjdesc;
begin
  if count > 0 then
  begin
    tdesc:=parray;
    for i := 0 to count - 1 do
    begin
      if tdesc^.ptempobj<>nil then
                                  tdesc^.ptempobj^.DrawWithAttrib({infrustumactualy,subrender}dc);
      inc(tdesc);
    end;
  end;

end;
procedure GDBSelectedObjArray.selectcurrentcontrolpoint;
var i: GDBInteger;
//  d: GDBDouble;
  td:tcontrolpointdist;
  tdesc:pselectedobjdesc;
begin
  td.pcontrolpoint := nil;
  td.disttomouse:=9999;
  SelectedCount:=0;
  if count > 0 then
  begin
    tdesc:=parray;
    for i := 0 to count - 1 do
    begin
      if tdesc^.pcontrolpoint<>nil then tdesc^.pcontrolpoint^.selectcurrentcontrolpoint(key);
      SelectedCount:=SelectedCount+tdesc^.pcontrolpoint^.SelectedCount;
      inc(tdesc);
    end;
  end;
end;
{destructor GDBSelectedObjArray.done;
begin
  if pa then

  GDBFreeMem(PArray);
end;}
begin
  {$IFDEF DEBUGINITSECTION}LogOut('UGDBSelectedObjArray.initialization');{$ENDIF}
end.
