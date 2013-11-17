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
unit gdbaligneddimension;
{$INCLUDE def.inc}

interface
uses UGDBTextStyleArray,UGDBXYZWStringArray,GDBAbstractText,gdbgenericdimension,gdbdimension,GDBPoint,ugdbdimstylearray,GDBMText,Varman,UGDBLayerArray,GDBGenericSubEntry,ugdbtrash,ugdbdrawingdef,GDBCamera,zcadsysvars,UGDBOpenArrayOfPObjects,strproc,UGDBOpenArrayOfByte,math,GDBText,GDBDevice,gdbcable,GDBTable,UGDBControlPointArray,geometry,GDBLine{,UGDBTableStyleArray},gdbasetypes{,GDBGenericSubEntry},GDBComplex,SysInfo,sysutils{,UGDBTable},UGDBStringArray{,GDBMTEXT,UGDBOpenArrayOfData},
{UGDBOpenArrayOfPV,UGDBObjBlockdefArray,}UGDBSelectedObjArray{,UGDBVisibleOpenArray},gdbEntity{,varman},varmandef,
GDBase{,UGDBDescriptor}{,GDBWithLocalCS},gdbobjectsconstdef,{oglwindowdef,}dxflow,memman,GDBSubordinated{,UGDBOpenArrayOfByte};
(*
Alligned dimension structure in DXF

   (11,21,31)
|----X(text)-----X (10,20,30)
|                |
|                |
|                |
X (13,23,33)     X (14,24,34)

*)
type
{EXPORT+}
PGDBObjAlignedDimension=^GDBObjAlignedDimension;
GDBObjAlignedDimension={$IFNDEF DELPHI}packed{$ENDIF} object(GDBObjDimension)
                      TextTParam,TextAngle,DimAngle:GDBDouble;
                      TextInside:GDBBoolean;
                      TextOffset:GDBVertex;
                      vectorD,vectorN,vectorT:GDBVertex;
                      dimtextw,dimtexth:GDBDouble;
                      dimtext:GDBString;
                      constructor init(own:GDBPointer;layeraddres:PGDBLayerProp;LW:GDBSmallint);
                      constructor initnul(owner:PGDBObjGenericWithSubordinated);
                      procedure DrawExtensionLine(p1,p2:GDBVertex;LineNumber:GDBInteger;const drawing:TDrawingDef);
                      procedure DrawDimensionLine(p1,p2:GDBVertex;const drawing:TDrawingDef);
                      procedure DrawDimensionText(p:GDBVertex;const drawing:TDrawingDef);
                      procedure CalcTextParam(dlStart,dlEnd:Gdbvertex);virtual;
                      procedure CalcTextAngle;virtual;
                      procedure FormatEntity(const drawing:TDrawingDef);virtual;
                      function Clone(own:GDBPointer):PGDBObjEntity;virtual;
                      //procedure DrawGeometry;

                      procedure addcontrolpoints(tdesc:GDBPointer);virtual;



                      function GetObjTypeName:GDBString;virtual;

                      function GetTextOffset(const drawing:TDrawingDef):GDBVertex;

                      procedure CalcDNVectors;virtual;
                      procedure CalcDefaultPlaceText(dlStart,dlEnd:Gdbvertex;const drawing:TDrawingDef);virtual;
                      function P10ChangeTo(tv:GDBVertex):GDBVertex;virtual;
                      function P11ChangeTo(tv:GDBVertex):GDBVertex;virtual;
                      //function P12ChangeTo(tv:GDBVertex):GDBVertex;virtual;
                      function P13ChangeTo(tv:GDBVertex):GDBVertex;virtual;
                      function P14ChangeTo(tv:GDBVertex):GDBVertex;virtual;
                      //function P15ChangeTo(tv:GDBVertex):GDBVertex;virtual;
                      //function P16ChangeTo(tv:GDBVertex):GDBVertex;virtual;
                       procedure SaveToDXF(var handle:TDWGHandle;var outhandle:{GDBInteger}GDBOpenArrayOfByte;const drawing:TDrawingDef);virtual;
                   end;
{EXPORT-}
function CorrectPointLine(q:GDBvertex;p1,p2:GDBvertex;out d:GDBDouble):GDBVertex;
function GetTFromDirNormalizedPoint(q:GDBvertex;var p1,dirNormalized:GDBvertex):double;
implementation
uses GDBManager,UGDBTableStyleArray,GDBBlockDef{,shared},log,UGDBOpenArrayOfPV,GDBCurve,UGDBDescriptor,GDBBlockInsert;
function CorrectPointLine(q:GDBvertex;p1,p2:GDBvertex;out d:GDBDouble):GDBVertex;
var w,l:GDBVertex;
    dist:GDBDouble;
begin
     //расстояние от точки до линии
     w:=VertexSub(q,p1);
     l:=VertexSub(p2,p1);
     dist:=scalardot(w,l)/scalardot(l,l);
     p1:=Vertexmorph(p1,p2,dist);
     d:=Vertexlength(q,p1);

     q:=geometry.Vertexmorphabs2(p1,q,d);
     result:=VertexAdd(p2,VertexSub(q,p1));
end;
function SetPointLine(d:GDBDouble;q:GDBvertex;p1,p2:GDBvertex):GDBVertex;
var w,l:GDBVertex;
    dist:GDBDouble;
begin
     w:=VertexSub(q,p1);
     l:=VertexSub(p2,p1);
     dist:=scalardot(w,l)/scalardot(l,l);
     p1:=Vertexmorph(p1,p2,dist);
     result:=geometry.Vertexmorphabs2(p1,q,d);
     //result:=VertexAdd(p2,VertexSub(q,p1));
end;
function GetTFromLinePoint(q:GDBvertex;var p1,p2:GDBvertex):double;
var w,l:GDBVertex;
begin
     w:=VertexSub(q,p1);
     l:=VertexSub(p2,p1);
     result:=scalardot(w,l)/scalardot(l,l);
end;
function GetTFromDirNormalizedPoint(q:GDBvertex;var p1,dirNormalized:GDBvertex):double;
var w:GDBVertex;
begin
     w:=VertexSub(q,p1);
     result:=scalardot(w,dirNormalized);
end;
procedure GDBObjAlignedDimension.SaveToDXF;
begin
  SaveToDXFObjPrefix(handle,outhandle,'DIMENSION','AcDbDimension');
  dxfvertexout(outhandle,10,DimData.P10InWCS);
  dxfvertexout(outhandle,11,DimData.P11InOCS);
  if DimData.TextMoved then
                           dxfGDBIntegerout(outhandle,70,1+128)
                       else
                           dxfGDBIntegerout(outhandle,70,1);
  dxfGDBStringout(outhandle,3,PDimStyle^.Name);
  dxfGDBStringout(outhandle,100,'AcDbAlignedDimension');
  dxfvertexout(outhandle,13,DimData.P13InWCS);
  dxfvertexout(outhandle,14,DimData.P14InWCS);
end;
procedure GDBObjAlignedDimension.CalcDefaultPlaceText(dlStart,dlEnd:Gdbvertex;const drawing:TDrawingDef);
begin
  //case PDimStyle.Text.DIMJUST;
  //end;{case}
  DimData.P11InOCS:=VertexMulOnSc({vertexadd(DimData.P13InWCS,DimData.P14InWCS)}vertexadd(dlStart,dlEnd),0.5);
  //DimData.P11InOCS:=VertexAdd(DimData.P11InOCS,vertexsub(DimData.P10InWCS,DimData.P14InWCS));
  DimData.P11InOCS:=VertexAdd(DimData.P11InOCS,getTextOffset(drawing));
end;
function GDBObjAlignedDimension.P10ChangeTo(tv:GDBVertex):GDBVertex;
var
    t,tl:GDBDouble;
    temp:GDBVertex;
begin
     tl:=scalardot(vertexsub(DimData.P14InWCS,DimData.P13InWCS),vectorD);
     temp:=VertexDmorph(DimData.P13InWCS,self.vectorD,tl);
     tv:=CorrectPointLine(tv,DimData.P13InWCS,temp,t);
     result:=tv;
     DimData.P10InWCS:=tv;
     self.CalcDNVectors;
     if (self.DimData.TextMoved)and(PDimStyle.Placing.DIMTMOVE=DTMMoveDimLine) then
                                   DimData.P11InOCS:=SetPointLine(t,DimData.P11InOCS,DimData.P13InWCS,temp)
                               {else
                                   CalcDefaultPlaceText(DimData.P13InWCS,DimData.P14InWCS);}
end;
function GDBObjAlignedDimension.P11ChangeTo(tv:GDBVertex):GDBVertex;
var
    t,tl:GDBDouble;
    tvertex,temp:GDBVERTEX;
begin
     result:=tv;
     DimData.TextMoved:=true;
     if PDimStyle.Placing.DIMTMOVE=DTMMoveDimLine then
     begin
     tl:=scalardot(vertexsub(DimData.P14InWCS,DimData.P13InWCS),vectorD);
     temp:=VertexDmorph(DimData.P13InWCS,self.vectorD,tl);

     t:=GettFromLinePoint(tv,DimData.P13InWCS,{DimData.P14InWCS}temp);
     tvertex:=geometry.Vertexmorph(DimData.P13InWCS,{DimData.P14InWCS}temp,t);
     tvertex:=vertexsub(tv,tvertex);
     DimData.P10InWCS:=VertexAdd({DimData.P14InWCS}temp,tvertex);
     end;
end;
(*
Alligned dimension structure in DXF

   (11,21,31)
|----X(text)-----X (10,20,30)
|                |
|                |
|                |
X (13,23,33)     X (14,24,34)

*)
function GDBObjAlignedDimension.P13ChangeTo(tv:GDBVertex):GDBVertex;
var
    t:GDBDouble;
    tvertex:GDBVERTEX;
begin
     result:=tv;
     if (self.DimData.TextMoved)and(PDimStyle.Placing.DIMTMOVE=DTMMoveDimLine) then
                                   begin
                                       t:=GettFromLinePoint(DimData.P11InOCS,tv,DimData.P14InWCS);
                                       tvertex:=geometry.Vertexmorph(tv,DimData.P14InWCS,t);
                                       tvertex:=vertexsub(DimData.P11InOCS,tvertex);
                                       DimData.P10InWCS:=VertexAdd(DimData.P14InWCS,tvertex);
                                   end
                               else
                                   begin
                                        t:=vertexlength(DimData.P10InWCS,DimData.P14InWCS);
                                        if GetCSDirFrom0x0y2D(vertexsub(DimData.P13InWCS,DimData.P14InWCS),vertexsub(DimData.P10InWCS,DimData.P14InWCS))=TCSDRight then
                                           t:=-t;
                                        if vertexlength(tv,DimData.P14InWCS)>eps then
                                                  begin
                                                  tvertex:=vertexsub(DimData.P14InWCS,tv);
                                                  tvertex:=geometry.vectordot(tvertex,self.Local.Basis.oz);
                                                  tvertex:=normalizevertex(tvertex);
                                                  end
                                           else
                                               tvertex:=geometry.x_Y_zVertex;

                                       tvertex:=VertexMulOnSc(tvertex,t);
                                       DimData.P10InWCS:=VertexAdd(DimData.P14InWCS,tvertex);
                                       DimData.P13InWCS:=tv;
                                       //CalcDefaultPlaceText(DimData.P13InWCS,DimData.P14InWCS);
                                   end
end;
function GDBObjAlignedDimension.P14ChangeTo(tv:GDBVertex):GDBVertex;
var
    t:GDBDouble;
    tvertex:GDBVERTEX;
begin
     result:=tv;
     if (self.DimData.TextMoved)and(PDimStyle.Placing.DIMTMOVE=DTMMoveDimLine) then
                                   begin
                                         t:=GettFromLinePoint(DimData.P11InOCS,DimData.P13InWCS,tv);
                                         tvertex:=geometry.Vertexmorph(DimData.P13InWCS,tv,t);
                                         tvertex:=vertexsub(DimData.P11InOCS,tvertex);
                                         DimData.P10InWCS:=VertexAdd(tv,tvertex);
                                   end
                                else
                                    begin
                                         t:=vertexlength(DimData.P10InWCS,DimData.P14InWCS);
                                         if GetCSDirFrom0x0y2D(vertexsub(DimData.P13InWCS,DimData.P14InWCS),vertexsub(DimData.P10InWCS,DimData.P14InWCS))=TCSDRight then
                                            t:=-t;
                                         if vertexlength(DimData.P13InWCS,tv)>eps then
                                                 begin
                                                       tvertex:=vertexsub(tv,DimData.P13InWCS);
                                                       tvertex:=geometry.vectordot(tvertex,self.Local.Basis.oz);
                                                       tvertex:=normalizevertex(tvertex);
                                                 end
                                            else
                                                tvertex:=geometry.x_Y_zVertex;

                                          tvertex:=VertexMulOnSc(tvertex,t);
                                          DimData.P10InWCS:=VertexAdd(tv,tvertex);
                                          DimData.P14InWCS:=tv;
                                          //CalcDefaultPlaceText(DimData.P13InWCS,DimData.P14InWCS);
                                    end
end;
function GDBObjAlignedDimension.GetObjTypeName;
begin
     result:=ObjN_ObjAlignedDimension;
end;
procedure GDBObjAlignedDimension.addcontrolpoints(tdesc:GDBPointer);
var pdesc:controlpointdesc;
begin
          PSelectedObjDesc(tdesc)^.pcontrolpoint^.init({$IFDEF DEBUGBUILD}'{4CBC9A73-A88D-443B-B925-2F0611D82AB0}',{$ENDIF}4);

          pdesc.selected:=false;
          pdesc.pobject:=nil;

          pdesc.pointtype:=os_p10;
          pdesc.worldcoord:=DimData.P10InWCS;
          PSelectedObjDesc(tdesc)^.pcontrolpoint^.add(@pdesc);

          pdesc.pointtype:=os_p11;
          pdesc.worldcoord:=DimData.P11InOCS;
          PSelectedObjDesc(tdesc)^.pcontrolpoint^.add(@pdesc);

          pdesc.pointtype:=os_p13;
          pdesc.worldcoord:=DimData.P13InWCS;
          PSelectedObjDesc(tdesc)^.pcontrolpoint^.add(@pdesc);

          pdesc.pointtype:=os_p14;
          pdesc.worldcoord:=DimData.P14InWCS;
          PSelectedObjDesc(tdesc)^.pcontrolpoint^.add(@pdesc);
end;

function GDBObjAlignedDimension.Clone;
var tvo: PGDBObjAlignedDimension;
begin
  GDBGetMem({$IFDEF DEBUGBUILD}'{5A1B005F-39F1-431B-B65E-0C532AEFA5D0}-GDBObjLine.Clone',{$ENDIF}GDBPointer(tvo), sizeof(GDBObjAlignedDimension));
  tvo^.init(bp.ListPos.owner,vp.Layer, vp.LineWeight);
  CopyVPto(tvo^);
  tvo^.DimData := DimData;
  tvo^.bp.ListPos.Owner:=own;
  tvo^.PDimStyle:=PDimStyle;
  result := tvo;
end;

constructor GDBObjAlignedDimension.initnul;
begin
  inherited initnul;
  PProjPoint:=nil;
  bp.ListPos.Owner:=owner;
  vp.ID := GDBAlignedDimensionID;
  DimData.P13InWCS := createvertex(1,1,0);
  DimData.P14InWCS:= createvertex(300,1,0);
end;
constructor GDBObjAlignedDimension.init;
begin
  inherited init(own,layeraddres, lw);
  PProjPoint:=nil;
  vp.ID := GDBAlignedDimensionID;
  DimData.P13InWCS := createvertex(1,1,0);
  DimData.P14InWCS:= createvertex(300,1,0);
end;

procedure GDBObjAlignedDimension.DrawExtensionLine(p1,p2:GDBVertex;LineNumber:GDBInteger;const drawing:TDrawingDef);
var
   pl:pgdbobjline;
   pp:pgdbobjpoint;
begin
  pp:=pointer(ConstObjArray.CreateInitObj(GDBpointID,@self));
  pp.vp.Layer:=vp.Layer;
  pp.vp.LineType:=vp.LineType;
  pp.P_insertInOCS:=p1;
  pp.FormatEntity(drawing);

  pl:=DrawExtensionLineLinePart(Vertexmorphabs2(p1,p2,PDimStyle.Lines.DIMEXO),Vertexmorphabs(p1,p2,PDimStyle.Lines.DIMEXE),drawing);
  pl.FormatEntity(drawing);
end;
procedure GDBObjAlignedDimension.DrawDimensionLine(p1,p2:GDBVertex;const drawing:TDrawingDef);
var
   l:GDBDouble;
   pl:pgdbobjline;
   tbp0,tbp1:TDimArrowBlockParam;
   pv:pGDBObjBlockInsert;
   p0inside,p1inside:GDBBoolean;
   pp1,pp2:GDBVertex;
   zangle:gdbdouble;
begin
  l:=geometry.Vertexlength(p1,p2);
  tbp0:=PDimStyle.GetDimBlockParam(0);
  tbp1:=PDimStyle.GetDimBlockParam(1);
  tbp0.width:=tbp0.width*PDimStyle.Arrows.DIMASZ;
  tbp1.width:=tbp1.width*PDimStyle.Arrows.DIMASZ;
  gdb.AddBlockFromDBIfNeed(@drawing,tbp0.name);
  gdb.AddBlockFromDBIfNeed(@drawing,tbp1.name);
  if tbp0.width=0 then
                      p0inside:=true
                  else
                      begin
                           if l-PDimStyle.Arrows.DIMASZ/2>(tbp0.width+tbp1.width) then
                                                            p0inside:=true
                                                        else
                                                            p0inside:=false;
                      end;
  if tbp1.width=0 then
                      p1inside:=true
                  else
                      begin
                           if l-PDimStyle.Arrows.DIMASZ/2>(tbp0.width+tbp1.width) then
                                                            p1inside:=true
                                                        else
                                                            p1inside:=false;
                      end;
  zangle:=vertexangle(createvertex2d(p1.x,p1.y),createvertex2d(p2.x,p2.y));
  if p0inside then
                  pointer(pv):=addblockinsert(@self,@self.ConstObjArray,p1,PDimStyle.Arrows.DIMASZ,ZAngle*180/pi-180,@tbp0.name[1])
              else
                  pointer(pv):=addblockinsert(@self,@self.ConstObjArray,p1,PDimStyle.Arrows.DIMASZ,ZAngle*180/pi,@tbp0.name[1]);
  pv^.formatentity(gdb.GetCurrentDWG^);

  if p1inside then
                  pointer(pv):=addblockinsert(@self,@self.ConstObjArray,p2,PDimStyle.Arrows.DIMASZ,ZAngle*180/pi,@tbp1.name[1])
              else
                  pointer(pv):=addblockinsert(@self,@self.ConstObjArray,p2,PDimStyle.Arrows.DIMASZ,ZAngle*180/pi-180,@tbp1.name[1]);
  pv^.formatentity(gdb.GetCurrentDWG^);
  if tbp0.width=0 then
                      pp1:=Vertexmorphabs(p2,p1,PDimStyle.Lines.DIMDLE)
                  else
                      begin
                      if p0inside then
                                      pp1:=Vertexmorphabs(p2,p1,-PDimStyle.Arrows.DIMASZ)
                                  else
                                      pp1:=p1;
                      end;
  if tbp1.width=0 then
                      pp2:=Vertexmorphabs(p1,p2,PDimStyle.Lines.DIMDLE)
                  else
                      begin
                      if p0inside then
                                      pp2:=Vertexmorphabs(p1,p2,-PDimStyle.Arrows.DIMASZ)
                                  else
                                      pp2:=p2;
                      end;

  pl:=DrawDimensionLineLinePart(pp1,pp2,drawing);
  pl.FormatEntity(drawing);
  case self.PDimStyle.Placing.DIMTMOVE of
  DTMMoveDimLine:
        begin
              if not TextInside then
                 begin
                      if TextTParam>0.5 then
                                            begin
                                                 pl:=DrawDimensionLineLinePart(pp2,DimData.P11InOCS,drawing);
                                                 pl.FormatEntity(drawing);
                                            end
                                        else
                                            begin
                                              pl:=DrawDimensionLineLinePart(pp1,DimData.P11InOCS,drawing);
                                              pl.FormatEntity(drawing);
                                            end;
                 end;
        end;
  DTMCreateLeader:
        begin
             if self.DimData.TextMoved then
             begin
             pl:=DrawDimensionLineLinePart(VertexMulOnSc(vertexadd(p1,p2),0.5),DimData.P11InOCS,drawing);
             pl.FormatEntity(drawing);
             pl:=DrawDimensionLineLinePart(DimData.P11InOCS,VertexDmorph(DimData.P11InOCS,VectorT,dimtextw),drawing);
             pl.FormatEntity(drawing);
             end;
        end;
  end;{case}
end;
function GDBObjAlignedDimension.GetTextOffset(const drawing:TDrawingDef):GDBVertex;
var
   l:GDBDouble;
   dimdir:gdbvertex;
   dimtxtstyle:PGDBTextStyle;
   txtlines:XYZWGDBGDBStringArray;
begin
   dimtext:=GetLinearDimStr(abs(scalardot(vertexsub(DimData.P14InWCS,DimData.P13InWCS),vectorD)));
   dimtxtstyle:=drawing.GetTextStyleTable^.getelement(0);
   txtlines.init(3);
   FormatMtext(dimtxtstyle.pfont,0,PDimStyle.Text.DIMTXT,dimtxtstyle^.prop.wfactor,dimtext,txtlines);
   dimtexth:=GetLinesH(GetLineSpaceFromLineSpaceF(1,PDimStyle.Text.DIMTXT),PDimStyle.Text.DIMTXT,txtlines);
   dimtextw:=GetLinesW(txtlines)*PDimStyle.Text.DIMTXT;
   txtlines.done;

     dimdir:=geometry.VertexSub(DimData.P10InWCS,DimData.P14InWCS);
     dimdir:=normalizevertex(dimdir);
     if (textangle=0)and(DimData.TextMoved) then
                        dimdir:=x_Y_zVertex;
     if (textangle<>0)or(abs(dimdir.x)<eps)or(DimData.TextMoved)then
     begin
          if PDimStyle.Text.DIMGAP>0 then
                                         l:=PDimStyle.Text.DIMGAP+{PDimStyle.Text.DIMTXT}dimtexth/2
                                     else
                                         l:=-2*PDimStyle.Text.DIMGAP+{PDimStyle.Text.DIMTXT}dimtexth/2;
     case PDimStyle.Text.DIMTAD of
                                  DTVPCenters:dimdir:=nulvertex;
                                  DTVPAbove:begin
                                                 if dimdir.y<-eps then
                                                                      dimdir:=geometry.VertexMulOnSc(dimdir,-1);
                                            end;
                                  DTVPJIS:dimdir:=nulvertex;
                                  DTVPBellov:begin
                                                 if dimdir.y>eps then
                                                                      dimdir:=geometry.VertexMulOnSc(dimdir,-1);
                                            end;
     end;
     result:=geometry.VertexMulOnSc(dimdir,l);
     end
        else
            result:=nulvertex;
end;
procedure GDBObjAlignedDimension.CalcTextAngle;
begin
   DimAngle:=vertexangle(NulVertex2D,CreateVertex2D(vectorD.x,vectorD.y));
   TextAngle:=CorrectAngleIfNotReadable(DimAngle);
end;

procedure GDBObjAlignedDimension.CalcTextParam;
var
  ptext:PGDBObjMText;
  ip: Intercept3DProp;
begin
  CalcTextAngle;

  ip:=geometry.intercept3dmy2({DimData.P13InWCS,DimData.P14InWCS}dlStart,dlEnd,DimData.P11InOCS,vertexadd(DimData.P11InOCS,self.vectorN));
  TextTParam:=ip.t1;//GettFromLinePoint(DimData.P11InOCS,DimData.P13InWCS,DimData.P14InWCS);
  if (TextTParam>0)and(TextTParam<1) then
                                         begin
                                              TextInside:=true;
                                         end
                                            else
                                                TextInside:=False;
  ip:=geometry.intercept3dmy2({DimData.P13InWCS,DimData.P14InWCS}dlStart,dlEnd,DimData.P11InOCS,vertexadd(DimData.P11InOCS,self.vectorN));
  if TextInside then
                    begin
                         if PDimStyle.Text.DIMTIH then
                                                      TextAngle:=0;
                    end
                else
                    begin
                         if PDimStyle.Text.DIMTOH then
                                                      TextAngle:=0;
                    end;
  vectorT.x:=cos(TextAngle);
  vectorT.y:=sin(TextAngle);
  vectorT.z:=0;
end;

procedure GDBObjAlignedDimension.DrawDimensionText(p:GDBVertex;const drawing:TDrawingDef);
var
  ptext:PGDBObjMText;
  ip: Intercept3DProp;
  txtlines:XYZWGDBGDBStringArray;
  dimtxtstyle:PGDBTextStyle;
  p2:GDBVertex;
begin
  //CalcTextParam;
  dimtext:=GetLinearDimStr(abs(scalardot(vertexsub(DimData.P14InWCS,DimData.P13InWCS),vectorD)));
  dimtxtstyle:=drawing.GetTextStyleTable^.getelement(0);
  {txtlines.init(3);
  FormatMtext(dimtxtstyle.pfont,0,PDimStyle.Text.DIMTXT,dimtxtstyle^.prop.wfactor,dimtext,txtlines);
  dimtexth:=GetLinesH(1,PDimStyle.Text.DIMTXT,txtlines);
  dimtextw:=GetLinesW(txtlines)*PDimStyle.Text.DIMTXT;
  txtlines.done;}

  ptext:=pointer(self.ConstObjArray.CreateInitObj(GDBMTextID,@self));
  ptext.vp.Layer:=vp.Layer;
  ptext.Template:=dimtext;
  TextOffset:=GetTextOffset(drawing);

  if PDimStyle.Text.DIMGAP<0 then
  begin
      dimtextw:=dimtextw-2*PDimStyle.Text.DIMGAP;
      dimtexth:=dimtexth-2*PDimStyle.Text.DIMGAP;
  end;
  if self.DimData.textmoved then
                   begin
                        p:=vertexadd(p,TextOffset);
                        if self.PDimStyle.Placing.DIMTMOVE=DTMCreateLeader then
                              begin
                                   p:=VertexDmorph(p,VectorT,dimtextw/2);
                              end;
                   end;
  ptext.Local.P_insert:=p;
  ptext.linespacef:=1;
  ptext.textprop.justify:=jsmc;
  ptext.textprop.angle:=TextAngle;
  ptext.Local.basis.ox.x:=cos(TextAngle);
  ptext.Local.basis.ox.y:=sin(TextAngle);
  ptext.TXTStyleIndex:=dimtxtstyle;
  ptext.textprop.size:=PDimStyle.Text.DIMTXT;
  ptext.FormatEntity(drawing);

  if PDimStyle.Text.DIMGAP<0 then
  begin
  p:=geometry.VertexDmorph(p,ptext.Local.basis.ox,-dimtextw/2);
  p:=geometry.VertexDmorph(p,ptext.Local.basis.oy,dimtexth/2);

  p2:=geometry.VertexDmorph(p,ptext.Local.basis.ox,dimtextw);
  DrawDimensionLineLinePart(p,p2,drawing).FormatEntity(drawing);

  p:=geometry.VertexDmorph(p2,ptext.Local.basis.oy,-dimtexth);
  DrawDimensionLineLinePart(p2,p,drawing).FormatEntity(drawing);

  p2:=geometry.VertexDmorph(p,ptext.Local.basis.ox,-dimtextw);
  DrawDimensionLineLinePart(p,p2,drawing).FormatEntity(drawing);

  p:=geometry.VertexDmorph(p2,ptext.Local.basis.oy,dimtexth);
  DrawDimensionLineLinePart(p2,p,drawing).FormatEntity(drawing);
  end;

end;
procedure GDBObjAlignedDimension.CalcDNVectors;
begin
     vectorD:=vertexsub(DimData.P14InWCS,DimData.P13InWCS);
     vectorD:=normalizevertex(vectorD);

     vectorN:=vertexsub(DimData.P10InWCS,DimData.P14InWCS);
     vectorN:=normalizevertex(vectorN);
end;

procedure GDBObjAlignedDimension.FormatEntity(const drawing:TDrawingDef);
var
  tv:GDBVertex;
  l:double;
begin
          ConstObjArray.cleareraseobj;
          CalcDNVectors;

          l:=GetTFromDirNormalizedPoint(DimData.P10InWCS,DimData.P14InWCS,vectorN);
          //DrawExtensionLine(DimData.P14InWCS,DimData.P10InWCS,0,drawing);
          DrawExtensionLine(DimData.P14InWCS,VertexDmorph(DimData.P14InWCS,self.vectorN,l),0,drawing);

          //tv:=geometry.VertexSub(DimData.P10InWCS,DimData.P14InWCS);
          //tv:=geometry.VertexAdd(DimData.P13InWCS,tv);
          //DrawExtensionLine(DimData.P13InWCS,tv,1,drawing);
          l:=GetTFromDirNormalizedPoint(DimData.P10InWCS,DimData.P13InWCS,vectorN);
          tv:=VertexDmorph(DimData.P13InWCS,self.vectorN,l);
          DrawExtensionLine(DimData.P13InWCS,tv,0,drawing);

          CalcTextAngle;
          if not self.DimData.TextMoved then
                                            CalcDefaultPlaceText(tv,DimData.P10InWCS,drawing);
          CalcTextParam(tv,DimData.P10InWCS);

          DrawDimensionText(DimData.P11InOCS,drawing);

          DrawDimensionLine(tv,DimData.P10InWCS,drawing);
   inherited;
end;
{procedure GDBObjAlignedDimension.DrawGeometry;
begin
     geom.DrawGeometry;
end;}
begin
  {$IFDEF DEBUGINITSECTION}LogOut('gdbaligneddimension.initialization');{$ENDIF}
end.
