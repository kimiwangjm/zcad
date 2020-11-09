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

unit uzcmessagedialogs;
{$INCLUDE def.inc}
interface
uses
    Controls,LCLTaskDialog,SysUtils,Forms,{$IFNDEF DELPHI}LCLtype,{$ELSE}windows,{$ENDIF}
    uzcinterface,uzclog,uzelongprocesssupport,Generics.Collections;

resourcestring
  rsMsgWndTitle='ZCAD';
  rsMsgNoShow='Don''t show this next time (for current task)';

type
  TZCMsgDlgIcon=(diWarning, diQuestion, diError, diInformation, diNotUsed);
  TZCMsgDialogResult=record
    ModalResult:integer;
    RadioRes: integer;
    SelectionRes: integer;
    VerifyChecked: Boolean;
  end;

  TMessagesDictionary=TDictionary<string,TZCMsgDialogResult>;

  TLPSSupporthelper=class
    class procedure EndLongProcessHandler(LPHandle:TLPSHandle;TotalLPTime:TDateTime);
  end;

procedure FatalError(errstr:String);
function zcMsgDlgError(ErrStr:String;NeedNoAsk:boolean=false):TZCMsgDialogResult;
function zcMsgDlgWarning(ErrStr:String;NeedNoAsk:boolean=false):TZCMsgDialogResult;
function zcMsgDlgInformation(ErrStr:String;NeedNoAsk:boolean=false):TZCMsgDialogResult;

implementation
var
  SuppressedMessages:TMessagesDictionary=nil;

class procedure TLPSSupporthelper.EndLongProcessHandler(LPHandle:TLPSHandle;TotalLPTime:TDateTime);
begin
  if lps.ActiveProcessCount=1 then
    if assigned(SuppressedMessages)then
      SuppressedMessages.clear;
end;

procedure FatalError(errstr:String);
var s:String;
begin
     s:='FATALERROR: '+errstr;
     programlog.logoutstr(s,0,LM_Fatal);
     s:=(s);
     ZCMsgCallBackInterface.Do_BeforeShowModal(nil);
     Application.MessageBox(@s[1],'',MB_OK or MB_ICONSTOP);
     ZCMsgCallBackInterface.Do_AfterShowModal(nil);

     halt(0);
end;
function getMsgID(MsgID:String):String;
var
  quoted:boolean;
  count,i,j:integer;
begin
  quoted:=false;
  count:=0;
  for i:=1 to length(MsgID) do begin
    if MsgID[i]='"' then quoted:=not quoted;
    if not quoted then inc(count);
  end;
  setlength(result,count);
  quoted:=false;
  j:=1;
  for i:=1 to length(MsgID) do begin
    if MsgID[i]='"' then quoted:=not quoted;
    if not quoted then begin
      result[j]:=MsgID[i];
      inc(j);
    end;
  end;
end;

function TZCMsgDlgIcon2TTaskDialogIcon(value:TZCMsgDlgIcon):TTaskDialogIcon;
begin
  case value of
    diWarning:result:=tiWarning;
   diQuestion:result:=tiQuestion;
      diError:result:=tiError;
diInformation:result:=tiInformation;
    diNotUsed:result:=tiNotUsed;
  end;
end;

function zcMsgDlg(MsgStr:String;aDialogIcon:TZCMsgDlgIcon;NeedNoAsk:boolean=false;MsgTitle:string=''):TZCMsgDialogResult;
  function isMsgSupressed(MsgID:String;var PrevResult:TZCMsgDialogResult):boolean;
  begin
    if assigned(SuppressedMessages) then
      if SuppressedMessages.TryGetValue(MsgID,PrevResult) then
        exit(true);
    result:=false;
  end;
  function isSupressedMsgPresent:boolean;
  begin
    if assigned(SuppressedMessages) then
      if SuppressedMessages.count>0 then
        exit(true);
    result:=false;
  end;
var
  Task:TTaskDialog;
  MsgID:String;
begin
  if isSupressedMsgPresent then begin
    MsgID:=getMsgID(MsgStr);
    if isMsgSupressed(MsgID,Result) then begin
      exit;
    end;
  end else
    MsgID:='';
  ZCMsgCallBackInterface.Do_BeforeShowModal(nil);

  if MsgTitle='' then
    Task.Title:=rsMsgWndTitle
  else
    Task.Title:=MsgTitle;

  Task.Inst:='';
  Task.Content:=MsgStr;
  if (NeedNoAsk)and(lps.ActiveProcessCount>0) then
    Task.Verify:=rsMsgNoShow
  else
    Task.Verify:='';
  Task.VerifyChecked := false;

  Result.ModalResult:=Task.Execute([],0,[tdfPositionRelativeToWindow],TZCMsgDlgIcon2TTaskDialogIcon(aDialogIcon));//controls.mrOk
  Result.RadioRes:=Task.RadioRes;
  Result.SelectionRes:=Task.SelectionRes;
  Result.VerifyChecked:=Task.VerifyChecked;

  ZCMsgCallBackInterface.Do_AfterShowModal(nil);

  if Task.VerifyChecked then begin
    if MsgID='' then
      MsgID:=getMsgID(MsgStr);
    if not assigned(SuppressedMessages) then
      SuppressedMessages:=TMessagesDictionary.create;
    SuppressedMessages.add(MsgID,Result);
  end;
end;
function zcMsgDlgError(ErrStr:String;NeedNoAsk:boolean=false):TZCMsgDialogResult;
var
  Task: TTaskDialog;
begin
  Result:=zcMsgDlg(ErrStr,diError,NeedNoAsk);
end;
function zcMsgDlgWarning(ErrStr:String;NeedNoAsk:boolean=false):TZCMsgDialogResult;
var
  Task: TTaskDialog;
begin
  Result:=zcMsgDlg(ErrStr,diWarning,NeedNoAsk);
end;
function zcMsgDlgInformation(ErrStr:String;NeedNoAsk:boolean=false):TZCMsgDialogResult;
var
  Task: TTaskDialog;
begin
  Result:=zcMsgDlg(ErrStr,diInformation,NeedNoAsk);
end;
initialization
  lps.AddOnLPEndHandler(TLPSSupporthelper.EndLongProcessHandler);
finalization
  if assigned(SuppressedMessages)then
    freeandnil(SuppressedMessages);
end.
