unit DEVICE_EL_VL_STAMP2;

interface

uses system,devices;
usescopy blocktype;
usescopy objname;

var

Code:GDBString;(*'Шифр'*)
Sheet:GDBString;(*'Страница'*)

implementation

begin

BTY_TreeCoord:='PLAN_EM_Штамп';
Device_Type:=TDT_SilaPotr;
Device_Class:=TDC_Shell;

NMO_Name:='ШТ0';
NMO_BaseName:='ШТ';
NMO_Suffix:='??';

Code:='??';
Sheet:='??';

end.