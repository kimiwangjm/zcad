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

unit uzcstrconsts;
{$INCLUDE def.inc}

interface
resourcestring
  {errors}
  rsInvalidInput='Invalid input';
  rsNotRegistred='Not registred';
  rsInvalidInputForPropery='Property "%s" for entity "%s": %s';
  rsDivByZero='Divide by zero';
  rsErrorPrefix='ERROR: ';

  rsInvalidIdentificator='"%s" not valid identificator';
  rsEntryAlreadyExist='Entry "%s" already exist';
  rsRenamedTo='%s "%s" renamed to "%s"';




  rsRevStr='Revision SVN:';
  rsInitialization='Initialization:';
  rsVInfoText='Unstable version';
  rsCommEntEeport='Registered commands - %d; registered entities - %d; registered DXF entities - %d';
  rsReleaseNotes='-UNDO\REDO - yet it is better not to use;'+#13#10+
                 #13#10+
                 '-If you have problems with rendering or selecting entities, run "Regen" and "RebuildTree" in command line;'#13#10+
                 #13#10+
                 '-To disable the display of this window comment out line "About" in the file "components\autorun.cmd". Encoding of all configuration files - UTF8;'#13#10;
  rsAuthor='Writeln by Andrey M. Zubarev';
  rsRunCommand='Running command';
  rsUnknownCommand='Unknown command';
  rsCommandNRInC='Command can not run';
  rsRunScript='Running script "%s";';
  rsUnassigned='Unassigned';
  rsProperty='Property';
  rsValue='Value';

  rsUnknownFileExt='Unknown file format "%s". Saving failed.';

  rsfardeffilenotfounf='File definition of the variables can not be found for the device "%s";';
  rsMenuNotFounf='Menu "%s" not found';

  rsUnnamedWindowTitle='Unnamed%-3.3d';
  rsHardUnnamed='Unnamed';

  rsNewLayerNameFormat='Layer%-3.3d';
  rsNewTextStyleNameFormat='Style%-3.3d';

  rsNameWithCounter='%s (%d)';
  rsNameAll='All';

  {files}
  rsUnableToOpenFile='Unable to open file "%s"';
  rsUnableToFindFile='Unable to find file "%s"';
  rsTemplateNotFound='Template file "%s" not found';

  {commands messages}
  rscmSpecifyFirstPoint='Specify first point:';
  rscmSpecifySecondPoint='Specify second point:';
  rscmSpecifyThirdPoint='Specify third point:';
  rscmSpecifyInsertPoint='Specify insert point:';
  rscmSpecifyScale='Specify scale:';
  rscmSpecifyRotate='Specify rotate:';

  rscmCantGetBlockToReplace='Unable get block name to replace';
  rscmInDwgTxtStyleNotDeffined='In drawing not defined any textstyle!';
  rscmNotCutHere='Do not cut off here';
  rscmNoCTU='No comands to undo. Complete the current command';
  rscmNoCTUSE='No comands to undo. UNDO stack is empty';
  rscmNoCTR='No comands to redo';
  rscmInStackData='In stack found following data:';
  rscmPoint='Point:';
  rscmFirstPoint='First point:';
  rscmSecondPoint='Second point:';
  rscmBasePoint='Base point:';
  rscmNewBasePoint='New base point:';
  rscmPickOrEnterAngle='Pick or enter angle:';
  rscmPickOrEnterScale='Pick or enter scale:';
  rscmInsertPoint='Insert point:';
  rscmCenterPointCircle='Center point for circle:';
  rscmPointOnCircle='Point on a circle:';

  rscmOptions2OI='Options are available in the Object Inspector';
  rscmSelOrSpecEntity='Select or specify the parameters entity!';
  rscmNEntitiesProcessed='%s entities processed';
  rscmNEntitiesDeselected='%d entities deselected';

  rscmNoBlocksOrDevices='No selected blocks or devices';
  rscmNoBlockDefInDWG='No BlockDef "%s" in the drawing';
  rscmNoBlockDefInDWGCXMenu='No BlockDef "%s" in the drawing. Use context menu';
  rscmInDwgBlockDefNotDeffined='In drawing not defined any BlockDefs!';

  rscmSelEntBeforeComm='Entities must be selected before run the command';
  rscmSelDevBeforeComm='Device must be selected before run the command';
  rscmSelDevsBeforeComm='Devices must be selected before run the command';
  rscmPolyNotSel='Poly entities not selected';
  rscm2VNotRemove='Only 2 vertex there is nothing to remove';

  rscmCommandOnlyCTXMenu='The command works only from context menu';

  {messages}
  rsClipboardIsEmpty='Clipboard is empty, there is nothing to paste';
  rsNotYetImplemented='Not yet implemented';
  rsLayerDefpaontsCanNotBePrinted='Layer DEFPOINTS can not be printed';
  rsLayerUsedIn='Layer "%s" used in: %d-model, %d-blockdef table';
  rsTextStyleUsedIn='Text style "%s" used in: %d-model, %d-blockdef table, %d-dimstyle table';
  rsCountTStylesPurged='%d Text styles purged';
  rsCountTStylesFound='%d Text styles found';
  rsLineTypeUsedIn='Line type "%s" used in: %d-model, %d-blockdef table';
  rsLineTypeDesk=';;Pattern length %f'#13#10'%s';
  rsSysLineTypeWarning='This is system line type!';
  rsQuitQuery='Do yo want to quit ZCAD?';
  rsCloseDWGQuery='Drawing "%s" not saved. Save?';
  rsCurrentLayerOff='The current layer is turned off';

  rsLayerMustBeSelected='Layer must be selected';
  rsUnableDelUsedLayer='Unable to delete, layer is used';

  rsStyleMustBeSelected='Style must be selected';
  rsUnableDelUsedStyle='Unable to delete, Style is used';
  rsCurrentStyleCannotBeDeleted='Current style cannot be deleted';

  rsSaveEmptyDWG='Drawing is empty. Sure?';
  rsZCADStarted='ZCAD v%s started';
  rsLoadingFontFile='Loading font file "%S"';
  rsTypeNotDefinedInModule='Type "%S" not defined in unit "%S"';
  rsUnableSelectFreeLayerName='Unable select free layer name';
  rsUnableSelectFreeTextStylerName='Unable select free text style name';

  {window names}
  rsOpenFile='Open file...';
  rsSaveFile='Save file...';
  rsAutoSave='Autosave';
  rsQuitCaption='Quit';
  rsWarningCaption='Warning!';
  rsAboutWndCaption = 'About ZCAD';
  rsProjectTree = 'Project Tree';
  rsProgramDB = 'Program DB';
  rsProjectDB = 'Project DB';
  rsBlocks='Blocks';
  rsUncategorized='Uncategorized';
  rsDevices='Devices';
  rsEquipment='Equipment';
  rsTextEditor='Text editor';
  rsTextEdCaption=' TEXT: ';
  rsMTextEditor='MText editor';


  rsdefaultpromot='Command';
  rsexprouttext='Expression %s return %s';

  rsGDBObjinspWndName='Object inspector';
  rsCommandLineWndName='Command line';
  rsDrawingWindowWndName='Drawings window';
  rsReCreating='Re-creating %s!';
  rsLayoutLoad='Error loading layout from file';
  rsToolBarNotFound='Toolbar "%s" is not found! Create a blank window';
  rsDifferent='Different';
  rsByLayer='ByLayer';
  rsByBlock='ByBlock';
  rsDefault='Default';
  rsSelectColor='Select color...';
  rsSelectLT='Select line type...';
  rsColorNum='Color %d';
  rsEmpty='Empty';
  rsmm='mm';
  rscompiledtimemsg='Done.  %s second';
  rsprocesstimemsg='%s:  %s second';

  rsncOGLc='OpenGL context is not created';
implementation

end.