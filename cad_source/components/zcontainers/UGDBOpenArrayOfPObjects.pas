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

unit UGDBOpenArrayOfPObjects;
{$INCLUDE def.inc}
interface
uses uzbtypesbase,uzctnrvectorp,
     uzbtypes,uzbmemman;
type
{Export+}
TZctnrVectorPObj{-}<PTObj,TObj>{//}={$IFNDEF DELPHI}packed{$ENDIF}
                                 object(TZctnrVectorP{-}<PTObj>{//})
                                       procedure cleareraseobjfrom(n:GDBInteger);virtual;
                                       procedure cleareraseobjfrom2(n:GDBInteger);virtual;
                                       function getDataMutable(index:GDBInteger):PGDBaseObject;
                                       procedure RemoveData(const data:PTObj);virtual;
                                       procedure pack;virtual;
                                       procedure cleareraseobj;virtual;
                                       destructor done;virtual;
                                 end;
GDBOpenArrayOfPObjects=packed object(TZctnrVectorPObj{-}<PGDBaseObject,GDBaseObject>{//})
                                   end;
PGDBOpenArrayOfPObjects=^GDBOpenArrayOfPObjects;
{Export-}
(*GDBOpenArrayOfPObjects={$IFNDEF DELPHI}packed{$ENDIF} object(GDBOpenArrayOfGDBPointer)
                             procedure cleareraseobj;virtual;
                             procedure eraseobj(ObjAddr:PGDBaseObject);virtual;
                             procedure cleareraseobjfrom(n:GDBInteger);virtual;
                             procedure cleareraseobjfrom2(n:GDBInteger);virtual;
                             procedure pack;virtual;
                             function GetObject(index:GDBInteger):PGDBaseObject;
                             destructor done;virtual;
                       end;*)
implementation
destructor TZctnrVectorPObj<PTObj,TObj>.done;
var
  p:PGDBaseObject;
  ir:itrec;
begin
  p:=beginiterate(ir);
  if p<>nil then
  repeat
       p.done;
       GDBFreeMem(GDBPointer(p));
       p:=iterate(ir);
  until p=nil;
  count:=0;
  inherited;
end;
procedure TZctnrVectorPObj<PTObj,TObj>.cleareraseobj;
var
  p:PGDBaseObject;
  ir:itrec;
begin
  p:=beginiterate(ir);
  if p<>nil then
  repeat
       p^.done;
       GDBFreeMem(GDBPointer(p));
       p:=iterate(ir);
  until p=nil;
  count:=0;
end;
procedure TZctnrVectorPObj<PTObj,TObj>.RemoveData(const data:PTObj);
//procedure TZctnrVectorPObj<T,TObj>.eraseobj;
var
  p:PTObj;
  ir:itrec;
begin
  p:=beginiterate(ir);
  if p<>nil then
  repeat
        if data=p then
                         begin
                              p.done;
                              pointer(ir.itp^):=nil;
                              GDBFreeMem(GDBPointer(p));
                              exit;
                         end;
       p:=iterate(ir);
  until p=nil;
end;
procedure TZctnrVectorPObj<PTObj,TObj>.pack;
var
pnew,pold:ppointer;
nc,c:integer;
begin
     if assigned(parray)then
     begin
     nc:=0;
     c:=0;
     pnew:=pointer(PArray);
     pold:=pointer(PArray);
     repeat
           pnew^:=pold^;
           if pnew^<>nil then
                            begin
                                 inc(nc);
                                 inc(GDBPlatformint(pnew),SizeOfData);
                            end;
           inc(GDBPlatformint(pold),SizeOfData);
           inc(c);
     until c=count;
     count:=nc;
     deleted:=0;
     end;
end;
function TZctnrVectorPObj<PTObj,TObj>.getDataMutable;
var pp:ppointer;
begin
     pp:=pointer(inherited getDataMutable(index));
     if pp=nil then
                   result:=nil
               else
                   result:=pp^;
end;
{begin
  result:=pointer(getDataMutable(index)^);
end;}
procedure TZctnrVectorPObj<T,TObj>.cleareraseobjfrom;
var
  p:PGDBaseObject;
      ir:itrec;
begin
  p:=beginiterate(ir);
  if p<>nil then
  repeat
       p^.done;
       if ir.itc>n then
                       GDBFreeMem(GDBPointer(p));
       p:=iterate(ir);
  until p=nil;
  count:=0;
end;
procedure TZctnrVectorPObj<PTObj,TObj>.cleareraseobjfrom2(n:GDBInteger);
var
  p:PGDBaseObject;
      ir:itrec;
begin
  p:=beginiterate(ir);
  if p<>nil then
  repeat
       if ir.itc>=n then
                       begin
                       p^.done;
                       GDBFreeMem(GDBPointer(p));
                       end;
       p:=iterate(ir);
  until p=nil;
  count:=n;
end;
(*destructor GDBOpenArrayOfPObjects.done;
var
  p:PGDBaseObject;
  ir:itrec;
begin
  p:=beginiterate(ir);
  if p<>nil then
  repeat
       p.done;
       GDBFreeMem(GDBPointer(p));
       p:=iterate(ir);
  until p=nil;
  count:=0;
  inherited;
end;
procedure GDBOpenArrayOfPObjects.pack;
var
pnew,pold:ppointer;
nc,c:integer;
begin
     if assigned(parray)then
     begin
     nc:=0;
     c:=0;
     pnew:=pointer(PArray);
     pold:=pointer(PArray);
     repeat
           pnew^:=pold^;
           if pnew^<>nil then
                            begin
                                 inc(nc);
                                 inc(GDBPlatformint(pnew),size{sizeof(pointer)});
                            end;
           inc(GDBPlatformint(pold),size{sizeof(pointer)});
           inc(c);
     until c=count;
     count:=nc;
     deleted:=0;
     end;
end;
procedure GDBOpenArrayOfPObjects.cleareraseobj;
var
  p:PGDBaseObject;
  ir:itrec;
begin
  p:=beginiterate(ir);
  if p<>nil then
  repeat
       p^.done;
       GDBFreeMem(GDBPointer(p));
       p:=iterate(ir);
  until p=nil;
  count:=0;
end;
procedure GDBOpenArrayOfPObjects.cleareraseobjfrom;
var
  p:PGDBaseObject;
      ir:itrec;
begin
  p:=beginiterate(ir);
  if p<>nil then
  repeat
       p^.done;
       if ir.itc>n then
                       GDBFreeMem(GDBPointer(p));
       p:=iterate(ir);
  until p=nil;
  count:=0;
end;
procedure GDBOpenArrayOfPObjects.cleareraseobjfrom2(n:GDBInteger);
var
  p:PGDBaseObject;
      ir:itrec;
begin
  p:=beginiterate(ir);
  if p<>nil then
  repeat
       if ir.itc>=n then
                       begin
                       p^.done;
                       GDBFreeMem(GDBPointer(p));
                       end;
       p:=iterate(ir);
  until p=nil;
  count:=n;
end;
procedure GDBOpenArrayOfPObjects.eraseobj;
var
  p:PGDBaseObject;
      ir:itrec;
begin
  p:=beginiterate(ir);
  if p<>nil then
  repeat
        if ObjAddr=p then
                         begin
                              p^.done;
                              pointer(ir.itp^):=nil;
                              GDBFreeMem(GDBPointer(p));
                              exit;
                         end;
       p:=iterate(ir);
  until p=nil;
end;
function GDBOpenArrayOfPObjects.GetObject;
begin
  result:=pointer(getDataMutable(index)^);
end;*)
begin
end.
