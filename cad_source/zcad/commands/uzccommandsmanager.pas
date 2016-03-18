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

unit uzccommandsmanager;
{$INCLUDE def.inc}
interface
uses UGDBOpenArrayOfPObjects,uzcsysvars,geometry,uzglabstractviewarea,paths,gdbobjectsconstdef,uzcctrldynamiccommandmenu,uzcinfoform,uzcstrconsts,{umytreenode,}uzcsysinfo,strproc,UGDBOpenArrayOfPointer,
     gdbasetypes,uzccommandsabstract, sysutils,gdbase,uzglviewareadata,
     memman,uzcshared,uzclog,varmandef,varman,ugdbdrawingdef,zcadinterface;
const
     tm:tmethod=(Code:nil;Data:nil);
     nullmethod:{tmethod}TButtonMethod=nil;
type
  tvarstack=object({varmanagerdef}varmanager)
            end;
  TOnCommandRun=procedure(command:string) of object;

  GDBcommandmanager=object(GDBOpenArrayOfPObjects)

                          lastcommand:GDBString;
                          pcommandrunning:PCommandRTEdObjectDef;

                          LatestRunPC:PCommandObjectDef;
                          LatestRunOperands:GDBString;
                          LatestRunPDrawing:PTDrawingDef;

                          CommandsStack:GDBOpenArrayOfGDBPointer;
                          ContextCommandParams:GDBPointer;
                          busy:GDBBoolean;
                          varstack:tvarstack;
                          DMenu:TDMenuWnd;
                          OnCommandRun:TOnCommandRun;
                          constructor init(m:GDBInteger);
                          function execute(const comm:string;silent:GDBBoolean;pdrawing:PTDrawingDef;POGLWndParam:POGLWndtype): GDBInteger;virtual;
                          function executecommand(const comm:string;pdrawing:PTDrawingDef;POGLWndParam:POGLWndtype): GDBInteger;virtual;
                          function executecommandsilent(const comm:pansichar;pdrawing:PTDrawingDef;POGLWndParam:POGLWndtype): GDBInteger;virtual;
                          procedure executecommandend;virtual;
                          procedure executecommandtotalend;virtual;
                          procedure ChangeModeAndEnd(newmode:TGetPointMode);
                          procedure executefile(fn:GDBString;pdrawing:PTDrawingDef;POGLWndParam:POGLWndtype);virtual;
                          function executelastcommad(pdrawing:PTDrawingDef;POGLWndParam:POGLWndtype): GDBInteger;virtual;
                          procedure sendpoint2command(p3d:gdbvertex; p2d:gdbvertex2di; mode:GDBByte;osp:pos_record;const drawing:TDrawingDef);virtual;
                          procedure CommandRegister(pc:PCommandObjectDef);virtual;
                          procedure run(pc:PCommandObjectDef;operands:GDBString;pdrawing:PTDrawingDef);virtual;
                          destructor done;virtual;
                          procedure cleareraseobj;virtual;
                          procedure DMShow;
                          procedure DMHide;
                          procedure DMClear;
                          //-----------------------------------------------------------------procedure DMAddProcedure(Text,HText:GDBString;proc:TonClickProc);
                          procedure DMAddMethod(Text,HText:GDBString;FMethod:TButtonMethod);
                          procedure DMAddProcedure(Text,HText:GDBString;FProc:TButtonProc);
                          function FindCommand(command:GDBString):PCommandObjectDef;
                          procedure PushValue(varname,vartype:GDBString;instance:GDBPointer);virtual;
                          function PopValue:vardesk;virtual;
                          function GetValue:vardesk;virtual;
                          function GetValueHeap:GDBInteger;
                          function CurrentCommandNotUseCommandLine:GDBBoolean;
                          procedure PrepairVarStack;
                          function Get3DPoint(prompt:GDBString;out p:GDBVertex):GDBBoolean;
                          function GetEntity(prompt:GDBString;out p:GDBPointer):GDBBoolean;
                          function Get3DPointInteractive(prompt:GDBString;out p:GDBVertex;const InteractiveProc:TInteractiveProcObjBuild;const PInteractiveData:GDBPointer):GDBBoolean;
                          function EndGetPoint(newmode:TGetPointMode):GDBBoolean;

                          procedure sendmousecoord(Sender:TAbstractViewArea;key: GDBByte);
                          procedure sendmousecoordwop(Sender:TAbstractViewArea;key: GDBByte);
                          procedure sendcoordtocommand(Sender:TAbstractViewArea;coord:GDBVertex;key: GDBByte);
                          procedure sendcoordtocommandTraceOn(Sender:TAbstractViewArea;coord:GDBVertex;key: GDBByte;pos:pos_record);
                    end;
var commandmanager:GDBcommandmanager;
function getcommandmanager:GDBPointer;export;
function GetCommandContext(pdrawing:PTDrawingDef;POGLWnd:POGLWndtype):TCStartAttr;
procedure ParseCommand(comm:string; out command,operands:GDBString);
{procedure startup;
procedure finalize;}
implementation
uses ugdbsimpledrawing,UGDBStringArray,{cmdline,}{UGDBDescriptor,}forms{,varman};

procedure GDBcommandmanager.sendcoordtocommandTraceOn(Sender:TAbstractViewArea;coord:GDBVertex;key: GDBByte;pos:pos_record);
var
   cs:integer;
begin
     //if .pcommandrunning<>nil then
     //if .pcommandrunning.IsRTECommand then
    cs:=CommandsStack.Count;
        sendpoint2command(coord,sender.param.md.mouse,key,pos,sender.pdwg^);

     if (key and MZW_LBUTTON)<>0 then
     if (pcommandrunning<>nil)and(cs=CommandsStack.Count) then
     begin
           inc(sender.tocommandmcliccount);
           sender.param.ontrackarray.otrackarray[0].worldcoord:=coord;
           sender.param.lastpoint:=coord;
           sender.create0axis;
           sender.project0axis;
     end;
     //end;
end;

procedure GDBcommandmanager.sendcoordtocommand(Sender:TAbstractViewArea;coord:GDBVertex;key: GDBByte);
begin
     if key=MZW_LBUTTON then Sender.param.lastpoint:=coord;
     sendpoint2command(coord, sender.param.md.mouse, key,nil,sender.pdwg^);
end;
procedure GDBcommandmanager.sendmousecoord(Sender:TAbstractViewArea;key: GDBByte);
begin
  if pcommandrunning <> nil then
    if sender.param.md.mouseonworkplan
    then
        begin
             sendcoordtocommand(sender,sender.param.md.mouseonworkplanecoord,key);
             //if key=MZW_LBUTTON then wa.param.lastpoint:=wa.param.md.mouseonworkplanecoord;
             //.pcommandrunning^.MouseMoveCallback(wa.param.md.mouseonworkplanecoord, wa.param.md.mouse, key,nil)
        end
    else
        begin
             sendcoordtocommand(sender,sender.param.md.mouseray.lbegin,key);
             //if key=MZW_LBUTTON then wa.param.lastpoint:=wa.param.md.mouseray.lbegin;
             //.pcommandrunning^.MouseMoveCallback(wa.param.md.mouseray.lbegin, wa.param.md.mouse, key,nil);
        end;
    //if key=MZW_LBUTTON then wa.param.ontrackarray.otrackarray[0].worldcoord:=wa.param.md.mouseonworkplanecoord;
end;
procedure GDBcommandmanager.sendmousecoordwop(Sender:TAbstractViewArea;key: GDBByte);
var
   tv:gdbvertex;
begin
  if pcommandrunning <> nil then
    if sender.param.ospoint.ostype <> os_none
    then
    begin
         begin
              {if (key and MZW_LBUTTON)<>0 then
                                              uzcshared.HistoryOutStr(floattostr(wa.param.ospoint.ostype));}
              tv:=sender.param.ospoint.worldcoord;
              if (key and MZW_SHIFT)<>0 then
                                            begin
                                                 key:=key and (not MZW_SHIFT);
                                                 tv:=Vertexmorphabs(sender.param.lastpoint,sender.param.ospoint.worldcoord,1);
                                            end;
              if (key and MZW_CONTROL)<>0 then
                                            begin
                                                 key:=key and (not MZW_CONTROL);
                                                 tv:=Vertexmorphabs(sender.param.lastpoint,sender.param.ospoint.worldcoord,-1);
                                            end;
              key:=key and (not MZW_CONTROL);
              key:=key and (not MZW_SHIFT);

              {if key=MZW_LBUTTON then
                                     begin
                                          inc(tocommandmcliccount);
                                          wa.param.ontrackarray.otrackarray[0].worldcoord:=tv;
                                     end;
              if (key and MZW_LBUTTON)<>0 then
                                              wa.param.lastpoint:=tv;
              .pcommandrunning^.MouseMoveCallback(tv, wa.param.md.mouse, key,@wa.param.ospoint);}

              sendcoordtocommandTraceOn(sender,tv,key,@sender.param.ospoint)
         end;
    end
    else
    begin
        {if key=MZW_LBUTTON then
                               begin
                               inc(tocommandmcliccount);
                               wa.param.ontrackarray.otrackarray[0].worldcoord:=wa.param.md.mouseonworkplanecoord;
                               end;}
        if sender.param.md.mouseonworkplan
        then
            begin
                 if sysvar.DWG.DWG_SnapGrid<>nil then
                 if not sysvar.DWG.DWG_SnapGrid^ then
                 sender.param.ospoint.worldcoord:=sender.param.md.mouseonworkplanecoord;
                 sendcoordtocommandTraceOn({wa.param.md.mouseonworkplanecoord}sender,sender.param.ospoint.worldcoord,key,nil)
                 //if key=MZW_LBUTTON then wa.param.lastpoint:=wa.param.md.mouseonworkplanecoord;
                 //.pcommandrunning.MouseMoveCallback(wa.param.md.mouseonworkplanecoord, wa.param.md.mouse, key,nil)
            end
        else
            begin
                 sender.param.ospoint.worldcoord:=sender.param.md.mouseray.lbegin;
                 sendcoordtocommandTraceOn(sender,sender.param.md.mouseray.lbegin,key,nil)
                 //if key=MZW_LBUTTON then wa.param.lastpoint:=wa.param.md.mouseray.lbegin;
                 //.pcommandrunning^.MouseMoveCallback(wa.param.md.mouseray.lbegin, wa.param.md.mouse, key,nil);
            end;
    end;
end;
function GDBcommandmanager.EndGetPoint(newmode:TGetPointMode):GDBBoolean;
begin
  if pcommandrunning<>nil then
  begin
  if (pcommandrunning^.IData.GetPointMode=TGPWait)or(pcommandrunning^.IData.GetPointMode=TGPWaitEnt) then
                              begin
                                  pcommandrunning^.IData.GetPointMode:=newmode;
                                  result:=true;
                              end
                          else
                              result:=false;
  end
     else
                              result:=false;
end;
function GDBcommandmanager.Get3DPointInteractive(prompt:GDBString;out p:GDBVertex;const InteractiveProc:TInteractiveProcObjBuild;const PInteractiveData:GDBPointer):GDBBoolean;
var
   savemode:GDBByte;//variable to store the current mode of the editor
                     //переменная для сохранения текущего режима редактора
begin
  //PTSimpleDrawing(pcommandrunning.pdwg)^.wa.asyncupdatemouse(0);
  Application.QueueAsyncCall(PTSimpleDrawing(pcommandrunning.pdwg)^.wa.asyncupdatemouse,0);
  savemode:=PTSimpleDrawing(pcommandrunning.pdwg)^.DefMouseEditorMode(MGet3DPoint or MGet3DPointWoOP,//set mode point of the mouse
                                                                                                     //устанавливаем режим указания точек мышью
                                                                      MGetControlpoint or MGetSelectionFrame or MGetSelectObject);//reset selection entities  mode
                                                                                                              //сбрасываем режим выбора примитивов мышью
  uzcshared.HistoryOutStr(prompt);
  pcommandrunning^.IData.GetPointMode:=TGPWait;
  pcommandrunning^.IData.PInteractiveData:=PInteractiveData;
  pcommandrunning^.IData.PInteractiveProc:=InteractiveProc;
  while (pcommandrunning^.IData.GetPointMode=TGPWait)and(not Application.Terminated) do
  begin
       Application.HandleMessage;
       //Application.ProcessMessages;
  end;
  if (pcommandrunning^.IData.GetPointMode=TGPPoint)and(not Application.Terminated) then
                                                                                 begin
                                                                                 p:=pcommandrunning^.IData.GetPointValue;
                                                                                 result:=true;
                                                                                 end
                                                                             else
                                                                                 begin
                                                                                 result:=false;
                                                                                 //uzcshared.HistoryOutStr('cancel');
                                                                                 end;
  if (pcommandrunning^.IData.GetPointMode<>TGPCloseDWG)then
  PTSimpleDrawing(pcommandrunning.pdwg)^.SetMouseEditorMode(savemode);//restore editor mode
                                                                      //восстанавливаем сохраненный режим редактора
end;

function GDBcommandmanager.Get3DPoint(prompt:GDBString;out p:GDBVertex):GDBBoolean;
begin
  result:=Get3DPointInteractive(prompt,p,nil,nil);
end;
function GDBcommandmanager.GetEntity(prompt:GDBString;out p:GDBPointer):GDBBoolean;
var
   savemode:GDBByte;
begin
  savemode:=PTSimpleDrawing(pcommandrunning.pdwg)^.DefMouseEditorMode(MGetSelectObject,
                                                                      MGet3DPoint or MGet3DPointWoOP or MGetSelectionFrame or MGetControlpoint);
  uzcshared.HistoryOutStr(prompt);
  pcommandrunning^.IData.GetPointMode:=TGPWaitEnt;
  pcommandrunning^.IData.PInteractiveData:=nil;
  pcommandrunning^.IData.PInteractiveProc:=nil;
  while (pcommandrunning^.IData.GetPointMode=TGPWaitEnt)and(not Application.Terminated) do
  begin
       Application.HandleMessage;
       //Application.ProcessMessages;
  end;
  if (pcommandrunning^.IData.GetPointMode=TGPEnt)and(not Application.Terminated) then
                                                                                 begin
                                                                                 p:=PTSimpleDrawing(pcommandrunning.pdwg)^.wa.param.SelDesc.LastSelectedObject;
                                                                                 result:=true;
                                                                                 end
                                                                             else
                                                                                 begin
                                                                                 result:=false;
                                                                                 //uzcshared.HistoryOutStr('cancel');
                                                                                 end;
  PTSimpleDrawing(pcommandrunning.pdwg)^.SetMouseEditorMode(savemode);//restore editor mode
                                                                      //восстанавливаем сохраненный режим редактора
end;

function GDBcommandmanager.GetValueHeap:GDBInteger;
begin
     result:=varstack.vardescarray.count;
end;
function GDBcommandmanager.CurrentCommandNotUseCommandLine:GDBBoolean;
begin
     if pcommandrunning<>nil then
                                 result:=pcommandrunning.NotUseCommandLine
                             else
                                 result:=true;
end;

procedure GDBcommandmanager.PushValue(varname,vartype:GDBString;instance:GDBPointer);
var
   vd: vardesk;
begin
     vd.name:=varname;
     //vd.data.Instance:=instance;
     vd.data.PTD:=SysUnit.TypeName2PTD(vartype);
     vd.data.Instance:=nil;
     varstack.createvariable(varname,vd);
     vd.data.PTD.CopyInstanceTo(instance,vd.data.Instance);
end;
function GDBcommandmanager.GetValue:vardesk;
var
lastelement:pvardesk;
begin
     lastelement:=pvardesk(varstack.vardescarray.getelement(varstack.vardescarray.Count-1));
     result:=lastelement^;
end;

function GDBcommandmanager.PopValue:vardesk;
var
lastelement:pvardesk;
begin
     lastelement:=pvardesk(varstack.vardescarray.getelement(varstack.vardescarray.Count-1));
     dec(varstack.vardescarray.Count);
     result:=lastelement^;
     lastelement.name:='';
     lastelement.username:='';
     lastelement.data.PTD:=nil;
     lastelement.data.Instance:=nil;
end;

function getcommandmanager:GDBPointer;
begin
     result:=@commandmanager;
end;
procedure GDBcommandmanager.DMShow;
begin
     //if assigned(cline) then
     if assigned({CLine.}DMenu) then
     begin
     //CLine.DMenu.ajustsize;
     {CLine.}DMenu.Show;
     end;
end;
procedure GDBcommandmanager.DMHide;
begin
     //if assigned(cline) then
     if assigned({CLine.}DMenu) then
     {CLine.}DMenu.Hide;
end;
procedure GDBcommandmanager.DMClear;
begin
     //if assigned(cline) then
     if assigned({CLine.}DMenu) then
     {CLine.}DMenu.clear;
end;
{procedure GDBcommandmanager.DMAddProcedure(Text,HText:GDBString;proc:TonClickProc);
begin
     if assigned(cline) then
     if assigned(CLine.DMenu) then
     CLine.DMenu.AddProcedure(Text,HText,Proc);
end;}
procedure GDBcommandmanager.DMAddProcedure;
begin
     //if assigned(cline) then
     if assigned({CLine.}DMenu) then
     {CLine.}DMenu.AddProcedure(Text,HText,FProc);
end;

procedure GDBcommandmanager.DMAddMethod;
begin
     //if assigned(cline) then
     if assigned({CLine.}DMenu) then
     {CLine.}DMenu.AddMethod(Text,HText,FMethod);
end;


procedure GDBcommandmanager.executefile;
var
   sa:GDBGDBStringArray;
   p:pstring;
   ir:itrec;
   oldlastcomm:GDBString;
   s:gdbstring;
begin
     s:=(ExpandPath(fn));
     historyoutstr(sysutils.format(rsRunScript,[s]));
     busy:=true;

     uzcshared.DisableCmdLine;

     oldlastcomm:=lastcommand;
     sa.init(200);
     sa.loadfromfile(s);
     //sa.getGDBString(1);
  p:=sa.beginiterate(ir);
  if p<>nil then
  repeat
        if (uppercase(pGDBString(p)^)<>'ABOUT')then
                                                    execute(p^,false,pdrawing,POGLWndParam)
                                                else
                                                    begin
                                                         if not sysparam.nosplash then
                                                         if sysparam.preloadedfile='' then
                                                                                      execute(p^,false,pdrawing,POGLWndParam)
                                                    end;
        p:=sa.iterate(ir);
  until p=nil;
  sa.FreeAndDone;
  lastcommand:=oldlastcomm;

     uzcshared.EnableCmdLine;
     busy:=false;
end;
procedure GDBcommandmanager.sendpoint2command;
var
   p:PCommandRTEdObjectDef;
   ir:itrec;
begin
     if pcommandrunning <> nil then
     if pcommandrunning^.pdwg={gdb.GetCurrentDWG}@drawing then
     if pcommandrunning.IsRTECommand then
     begin
          pcommandrunning^.MouseMoveCallback(p3d,p2d,mode,osp);
     end
     else if pcommandrunning^.IData.GetPointMode=TGPWait then
                                      begin
                                           if mode=MZW_LBUTTON then
                                           begin
                                                if assigned(pcommandrunning^.IData.PInteractiveProc) then
                                                pcommandrunning^.IData.PInteractiveProc(pcommandrunning^.IData.PInteractiveData,p3d,true);
                                                pcommandrunning^.IData.GetPointMode:=TGPpoint;
                                                pcommandrunning^.IData.GetPointValue:=p3d;
                                           end
                                           else
                                               if assigned(pcommandrunning^.IData.PInteractiveProc) then
                                                pcommandrunning^.IData.PInteractiveProc(pcommandrunning^.IData.PInteractiveData,p3d,false);
                                      end;
     //clearotrack;
        p:=CommandsStack.beginiterate(ir);
        if p<>nil then
        repeat
              if p^.pdwg={gdb.GetCurrentDWG}@drawing then
              if p^.IsRTECommand then
                                                       begin
                                                            (p)^.MouseMoveCallback(p3d,p2d,mode,osp);
                                                       end;

              p:=CommandsStack.iterate(ir);
        until p=nil;
end;
procedure GDBcommandmanager.cleareraseobj;
var p:PCommandObjectDef;
    ir:itrec;
begin
  p:=beginiterate(ir);
  if p<>nil then
  repeat
       p^.done;
       if p^.dyn then GDBFreeMem(GDBPointer(p));
       p:=iterate(ir);
  until p=nil;
  count:=0;
end;
function GetCommandContext(pdrawing:PTDrawingDef;POGLWnd:POGLWndtype):TCStartAttr;
begin
     result:=0;
     if pdrawing<>nil then
                          begin
                               result:=result or CADWG;
                               if pdrawing^.CanRedo then
                                                        result:=result or CACanRedo;
                               if pdrawing^.CanUndo then
                                                        result:=result or CACanUndo;
                               if pdrawing^.GetChangeStampt then
                                                                result:=result or CADWGChanged;
                          end;
     if POGLWnd<>nil then
                         begin
                              if POGLWnd^.SelDesc.Selectedobjcount=1 then
                                                                         result:=result or CASelEnt;
                              //else
                              if POGLWnd^.SelDesc.Selectedobjcount>0 then
                                                                         result:=result or CASelEnts;
                         end;
end;
procedure ParseCommand(comm:string; out command,operands:GDBString);
var
   {i,}p1,p2: GDBInteger;
begin
  p1:=pos('(',comm);
  p2:=pos(')',comm);
  if  p1<1 then
               begin
                    p1:=length(comm)+1;
                    p2:=p1;
               end;
  command:=copy(comm,1,p1-1);
  operands:=copy(comm,p1+1,p2-p1-1);
  command:=uppercase(Command);
end;
function GDBcommandmanager.FindCommand(command:GDBString):PCommandObjectDef;
var
   p:PCommandObjectDef;
   ir:itrec;
begin
   p:=beginiterate(ir);
   if p<>nil then
   repeat
         if uppercase(p^.CommandName)=command then
                                                  begin
                                                       result:=p;
                                                       exit;
                                                  end;

         p:=iterate(ir);
   until p=nil;
   result:=nil;
end;
procedure GDBcommandmanager.run(pc:PCommandObjectDef;operands:GDBString;pdrawing:PTDrawingDef);
var
   pd:PTSimpleDrawing;
begin
   pd:={gdb.GetCurrentDWG}PTSimpleDrawing(pdrawing);
   if pd<>nil then
   if ((pc^.CEndActionAttr)and CEDWGNChanged)=0 then
                                                   pd.ChangeStampt(true);
          if pcommandrunning<>nil then
                                      begin
                                           if pc^.overlay then
                                                              begin
                                                                   if CommandsStack.IsObjExist(pc)
                                                                   then
                                                                       self.executecommandtotalend
                                                                   else
                                                                       begin
                                                                            CommandsStack.AddRef(pcommandrunning^)
                                                                       end;
                                                              end
                                                          else
                                                              begin
                                                                      if EndGetPoint(TGPOtherCommand) then
                                                                       begin
                                                                            LatestRunPC:=pc;
                                                                            LatestRunOperands:=operands;
                                                                            LatestRunPDrawing:=pdrawing;

                                                                            exit;
                                                                       end;
                                                              self.executecommandtotalend;

                                                              end;
                                      end;
          pcommandrunning := pointer(pc);
          pcommandrunning^.pdwg:=pd;
          pcommandrunning^.CommandStart(pansichar(operands));
end;
function GDBcommandmanager.execute(const comm:string;silent:GDBBoolean;pdrawing:PTDrawingDef;POGLWndParam:POGLWndtype): GDBInteger;
var //i,p1,p2: GDBInteger;
    command,operands:GDBString;
    cc:TCStartAttr;
    pfoundcommand:PCommandObjectDef;
    //p:pchar;
begin
  if length(comm)>0 then
  if comm[1]<>';' then
  begin
  ParseCommand(comm,command,operands);

  pfoundcommand:=FindCommand(command);

  if pfoundcommand<>nil then
  begin
    begin
      cc:=GetCommandContext(pdrawing,POGLWndParam);
      if ((cc xor pfoundcommand^.CStartAttrEnableAttr)and pfoundcommand^.CStartAttrEnableAttr)=0
      then
          begin

          //lastcommand := command;

          if silent then
                        programlog.LogOutFormatStr('GDBCommandManager.ExecuteCommandSilent(%s)',[pfoundcommand^.CommandName],lp_OldPos,LM_Info)
                    else
                        begin
                        historyoutstr(rsRunCommand+':'+pfoundcommand^.CommandName);
                        lastcommand := command;
                        if not (busy) then
                        if assigned(OnCommandRun) then
                                                      OnCommandRun(command);
                        end;

          run(pfoundcommand,operands,pdrawing);
          if pcommandrunning<>nil then
                                      //if assigned(CLine) then
                                      //CLine.SetMode(CLCOMMANDRUN);
                                      if assigned(SetCommandLineMode) then
                                      SetCommandLineMode(CLCOMMANDRUN);
          end
     else
         begin
              historyout(@rsCommandNRInC[1]);
         end;
    end;
  end
  else historyout(GDBPointer(rsUnknownCommand+':"'+command+'"'));
  end;
  command:='';
  operands:='';
end;
function GDBcommandmanager.executecommand(const comm:string;pdrawing:PTDrawingDef;POGLWndParam:POGLWndtype): GDBInteger;
begin
     if not busy then
                     result:=execute(comm,false,pdrawing,POGLWndParam)
                 else
                     uzcshared.ShowError(rsCommandNRInC);
end;
function GDBcommandmanager.executecommandsilent{(const comm:pansichar): GDBInteger};
begin
     if not busy then
     result:=execute(comm,true,pdrawing,POGLWndParam);
end;
procedure GDBcommandmanager.PrepairVarStack;
var
    ir:itrec;
    pvd:pvardesk;
    value:GDBString;
begin
     if self.varstack.vardescarray.Count<>0 then
     begin
     uzcshared.HistoryOutStr(rscmInStackData);
     pvd:=self.varstack.vardescarray.beginiterate(ir);
     if pvd<>nil then
     repeat
           value:=pvd.data.PTD.GetValueAsString(pvd.data.Instance);
           uzcshared.HistoryOutStr(pvd.data.PTD.TypeName+':'+value);

     pvd:=self.varstack.vardescarray.iterate(ir);
     until pvd=nil;
     end;
     varstack.vardescarray.Clear;
     varstack.vararray.Clear;
end;

procedure GDBcommandmanager.executecommandend;
var
   temp:PCommandRTEdObjectDef;
   temp2:PCommandObjectDef;
begin
  //ReturnToDefault;
  if EndGetPoint(TGPCancel) then
                      exit;
  temp:=pcommandrunning;
  pcommandrunning := nil;
  if temp<>nil then
                   temp^.CommandEnd;
  if pcommandrunning=nil then
  //if assigned(cline) then
  //                 CLine.SetMode(CLCOMMANDREDY);
  if assigned(SetCommandLineMode) then
                   SetCommandLineMode(CLCOMMANDREDY);
  if self.CommandsStack.Count>0 then
                                    begin
                                         pcommandrunning:=ppointer(CommandsStack.getelement(CommandsStack.Count-1))^;
                                         dec(CommandsStack.Count);
                                         pcommandrunning.CommandContinue;
                                    end
                                else
                                    begin
                                         self.DMHide;
                                         self.DMClear;
                                         PrepairVarStack;
                                    end;
   ContextCommandParams:=nil;
   if LatestRunPC<>nil then
   begin
        temp2:=LatestRunPC;
        LatestRunPC:=nil;
        GDBcommandmanager.run(temp2,LatestRunOperands,LatestRunPDrawing);
   end
   else if pcommandrunning<>nil then if pcommandrunning^.IData.GetPointMode=TGPCloseApp then
                                        Application.QueueAsyncCall(AppCloseProc, 0);
end;
procedure GDBcommandmanager.ChangeModeAndEnd(newmode:TGetPointMode);
var
   temp:PCommandRTEdObjectDef;
begin
  if EndGetPoint(newmode) then
                      exit;
  self.DMHide;
  self.DMClear;

  temp:=pcommandrunning;
  pcommandrunning := nil;
  if temp<>nil then
                   temp^.CommandEnd;
  if pcommandrunning=nil then
                             if assigned(SetCommandLineMode) then
                             SetCommandLineMode(CLCOMMANDREDY);
  CommandsStack.Clear;
  ContextCommandParams:=nil;
end;

procedure GDBcommandmanager.executecommandtotalend;
begin
  ChangeModeAndEnd(TGPCancel);
end;
function GDBcommandmanager.executelastcommad(pdrawing:PTDrawingDef;POGLWndParam:POGLWndtype): GDBInteger;
begin
  result:=executecommand(lastcommand,pdrawing,POGLWndParam);
end;
constructor GDBcommandmanager.init;
var
      pint:PGDBInteger;
begin
  inherited init({$IFDEF DEBUGBUILD}'{8B10F808-46AD-4EF1-BCDD-55B74D27187B}',{$ENDIF}m);
  //pcommandrunning^.GetPointMode:=TGPCancel;
  CommandsStack.init({$IFDEF DEBUGBUILD}'{8B10F808-46AD-4EF1-BCDD-55B74D27187B}',{$ENDIF}10);
  varstack.init;
  DMenu:=TDMenuWnd.CreateNew(application);
  if SavedUnit<>nil then
  begin
  pint:=SavedUnit.FindValue('DMenuX');
  if assigned(pint)then
                       DMenu.Left:=pint^;
  pint:=SavedUnit.FindValue('DMenuY');
  if assigned(pint)then
                       DMenu.Top:=pint^;
  end;
end;
procedure GDBcommandmanager.CommandRegister(pc:PCommandObjectDef);
begin
  if count=max then exit;
  add(@pc);
end;
procedure comdeskclear(p:GDBPointer);
begin
     {pvardesk(p)^.name:='';
     pvardesk(p)^.vartype:=0;
     pvardesk(p)^.vartypecustom:=0;
     gdbfreemem(pvardesk(p)^.pvalue);}
end;
destructor GDBcommandmanager.done;
begin
     {self.freewithprocanddone(comdeskclear);}
     lastcommand:='';
     inherited done;
     CommandsStack.done;
     varstack.Done;
end;
{procedure startup;
begin
  commandmanager.init(1000);
end;
procedure finalize;
begin
  commandmanager.FreeAndDone;
end;}
initialization
     commandmanager.init(1000);
finalization
     commandmanager.FreeAndDone;
end.