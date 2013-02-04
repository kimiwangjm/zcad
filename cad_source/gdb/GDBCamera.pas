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

unit GDBCamera;
{$INCLUDE def.inc}

interface
uses zcadstrconsts,gdbase,{ogltypes,}gdbasetypes,geometry;

type
GDBProjectProc=function (objcoord:GDBVertex; out wincoord:GDBVertex):Integer of object;
{REGISTEROBJECTTYPE GDBObjCamera}
{EXPORT+}
PGDBObjCamera=^GDBObjCamera;
GDBObjCamera=object(GDBBaseCamera)
                   modelMatrixLCS:DMatrix4D;
                   zminLCS,zmaxLCS:GDBDouble;
                   frustumLCS:ClipArray;
                   clipLCS:DMatrix4D;
                   projMatrixLCS:DMatrix4D;
                   notuseLCS:GDBBoolean;
                   procedure getfrustum(mm,pm:PDMatrix4D;var _clip:DMatrix4D;var _frustum:ClipArray);
                   procedure RotateInLocalCSXY(ux,uy:GDBDouble);
                   procedure MoveInLocalCSXY(oldx,oldy:GDBDouble;ax:gdbvertex);
                   function GetObjTypeName:GDBString;virtual;
                   constructor initnul;

                   procedure NextPosition;virtual;
             end;
{EXPORT-}

implementation
uses shared,log;
procedure GDBObjCamera.NextPosition;
begin
     Inc(POSCOUNT);
     inc(VISCOUNT);
end;
constructor GDBObjCamera.initnul;
begin
     POSCOUNT:=1;
     VISCOUNT:=1;
end;
function GDBObjCamera.GetObjTypeName;
begin
     //pointer(result):=typeof(testobj);
     result:='GDBObjCamera';

end;
procedure GDBObjCamera.getfrustum;
//var t:GDBDouble;
begin
   //t:=sizeof(modelmatrix);
   _clip:=MatrixMultiply(mm^,pm^);
   _frustum:=calcfrustum(@_clip);
end;
procedure GDBObjCamera.RotateInLocalCSXY(ux,uy:GDBDouble);
var
  //glmcoord1: gdbpiece;
  tempmatr,{tempmatr2,}rotmatr:DMatrix4D;
  //tv,tv2:gdbvertex4d;
  //ax,ay:gdbvertex;
  //len:GDBDouble;

begin
      tempmatr:=onematrix;
      pgdbvertex(@tempmatr[0])^:=prop.xdir;
      pgdbvertex(@tempmatr[1])^:=prop.ydir;
      pgdbvertex(@tempmatr[2])^:=prop.look;
      rotmatr:=MatrixMultiply(CreateRotationMatrixY(sin(uy),cos(uy)),CreateRotationMatrixX(sin(ux),cos(uy)));
      tempmatr:=MatrixMultiply(rotmatr,tempmatr);

      prop.xdir:=pgdbvertex(@tempmatr[0])^;
      prop.ydir:=pgdbvertex(@tempmatr[1])^;
      prop.look:=pgdbvertex(@tempmatr[2])^;

      prop.look:=NormalizeVertex(prop.look);
      prop.xdir := CrossVertex(prop.ydir,prop.look);
      prop.xdir:=NormalizeVertex(prop.xdir);
      prop.ydir := CrossVertex(prop.look,prop.xdir);
end;
procedure GDBObjCamera.MoveInLocalCSXY(oldx,oldy:GDBDouble;ax:gdbvertex);
var
  //glmcoord1: gdbpiece;
  tempmatr,{tempmatr2,}rotmatr:DMatrix4D;
  tv,tv2:gdbvertex4d;
  //ay:gdbvertex;
  //ux,uy:GDBDouble;
  len,d:GDBDouble;

begin
      tempmatr:=onematrix;
      //tempmatr2:=onematrix;
      rotmatr:=onematrix;
      pgdbvertex(@rotmatr[0])^:=prop.xdir;
      pgdbvertex(@rotmatr[1])^:=prop.ydir;
      pgdbvertex(@rotmatr[2])^:=prop.look;

      tv2.x:=-oldx;
      tv2.y:=-oldy;
      tv2.z:=0;
      tv2.w:=1;

      len:=onevertexlength(ax);
      d:=sqrt(tv2.x*tv2.x+tv2.y*tv2.y+tv2.z*tv2.z);
      if d>eps then
      begin
      len:=len/d;
      //if (len<eps)or(len>100)  then
      if (abs(ax.x)>eps)or(abs(ax.y)>eps)  then
      begin

      tv2.x:=tv2.x*len;
      tv2.y:=tv2.y*len;

      tv:=tv2;

      tempmatr:=rotmatr;

      tv:=vectortransform(tv,tempmatr);

      //normalize4d(tv);

      tv.x:=tv.x;
      Pgdbvertex(@rotmatr[3])^:=prop.point;
      tempmatr:=CreateTranslationMatrix(Pgdbvertex(@tv)^);
      tempmatr:=MatrixMultiply(rotmatr,tempmatr);
      prop.point:=Pgdbvertex(@tempmatr[3])^;
      end;

      end else
              ShowError('GDBObjCamera.MoveInLocalCSXY:'+rsDivByZero);
              //shared.historyoutstr('Divide by zero');
end;



begin
  {$IFDEF DEBUGINITSECTION}LogOut('GDBCamera.initialization');{$ENDIF}
end.
