{-------------------------------------------------------------------------------
The contents of this file are subject to the Mozilla Public License
Version 1.1 (the "License"); you may not use this file except in compliance
with the License. You may obtain a copy of the License at
http://www.mozilla.org/MPL/

Software distributed under the License is distributed on an "AS IS" basis,
WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License for
the specific language governing rights and limitations under the License.

The Original Code is: SynHighlighterCS.pas, released 2001-10-28.
The Original Code is based on SynHighlighterCpp.pas, released 2000-04-10,
which in turn is based on the dcjCppSyn.pas file from the mwEdit component
suite by Martin Waldenburg and other developers, the Initial Author of this file
is Michael Trier.
Unicode translation by Ma�l H�rz.
All Rights Reserved.

Contributors to the SynEdit and mwEdit projects are listed in the
Contributors.txt file.

Alternatively, the contents of this file may be used under the terms of the
GNU General Public License Version 2 or later (the "GPL"), in which case
the provisions of the GPL are applicable instead of those above.
If you wish to allow use of your version of this file only under the terms
of the GPL and not to allow others to use your version of this file
under the MPL, indicate your decision by deleting the provisions above and
replace them with the notice and other provisions required by the GPL.
If you do not delete the provisions above, a recipient may use your version
of this file under either the MPL or the GPL.

$Id: SynHighlighterCS.pas,v 1.8.2.7 2008/09/14 16:24:59 maelh Exp $

You may retrieve the latest version of SynEdit from the SynEdit home page,
located at http://SynEdit.SourceForge.net

You may retrieve the latest version of this file from
http://www.ashleybrown.co.uk/synedit/

Known Issues:
  - strings on multiple lines are not supported 
-------------------------------------------------------------------------------}
{
@abstract(Provides a C# syntax highlighter for SynEdit)
@author(Ashley Brown)
@created(2001)
@lastmod(2001-10-20)
The SynHighlighterCS unit provides SynEdit with a C# syntax highlighter.
Based on SynHighlighterCpp.pas
}

unit SynEdit32.Highlighter.CS;

{$I SynEdit32.Inc}

interface

uses
  Graphics,
  SynEdit32.Types,
  SynEdit32.Highlighter,
  SynEdit32.MiscClasses,
  SynEdit32.Unicode,
  SysUtils,
  Classes;

type
  TtkTokenKind = (tkAsm, tkComment, tkDirective, tkIdentifier, tkKey, tkNull,
    tkNumber, tkSpace, tkString, tkSymbol, tkUnknown);

  TxtkTokenKind = (
    xtkAdd, xtkAddAssign, xtkAnd, xtkAndAssign, xtkArrow, xtkAssign,
    xtkBitComplement, xtkBraceClose, xtkBraceOpen, xtkColon, xtkComma,
    xtkDecrement, xtkDivide, xtkDivideAssign, xtkEllipse, xtkGreaterThan,
    xtkGreaterThanEqual, xtkIncOr, xtkIncOrAssign, xtkIncrement, xtkLessThan,
    xtkLessThanEqual, xtkLogAnd, xtkLogComplement, xtkLogEqual, xtkLogOr,
    xtkMod, xtkModAssign, xtkMultiplyAssign, xtkNotEqual, xtkPoint, xtkQuestion,
    xtkRoundClose, xtkRoundOpen, xtkScopeResolution, xtkSemiColon, xtkShiftLeft,
    xtkShiftLeftAssign, xtkShiftRight, xtkShiftRightAssign, xtkSquareClose,
    xtkSquareOpen, xtkStar, xtkSubtract, xtkSubtractAssign, xtkXor,
    xtkXorAssign);

  TRangeState = (rsUnknown, rsAnsiC, rsAnsiCAsm, rsAnsiCAsmBlock, rsAsm,
    rsAsmBlock, rsDirective, rsDirectiveComment, rsString34, rsString39,
    rsMultiLineString);

  PIdentFuncTableFunc = ^TIdentFuncTableFunc;
  TIdentFuncTableFunc = function (Index: Integer): TtkTokenKind of object;

  TSynEdit32HighlighterCS = class(TSynEdit32CustomHighlighter)
  private
    FAsmStart: Boolean;
    FRange: TRangeState;
    FTokenID: TtkTokenKind;
    FExtTokenID: TxtkTokenKind;
    FIdentFuncTable: array[0..210] of TIdentFuncTableFunc;
    FAsmAttri: TSynEdit32HighlighterAttributes;
    FCommentAttri: TSynEdit32HighlighterAttributes;
    FDirecAttri: TSynEdit32HighlighterAttributes;
    FIdentifierAttri: TSynEdit32HighlighterAttributes;
    FInvalidAttri: TSynEdit32HighlighterAttributes;
    FKeyAttri: TSynEdit32HighlighterAttributes;
    FNumberAttri: TSynEdit32HighlighterAttributes;
    FSpaceAttri: TSynEdit32HighlighterAttributes;
    FStringAttri: TSynEdit32HighlighterAttributes;
    FSymbolAttri: TSynEdit32HighlighterAttributes;
    function AltFunc(Index: Integer): TtkTokenKind;
    function FuncAbstract(Index: Integer): TtkTokenKind;
    function FuncAs(Index: Integer): TtkTokenKind;
    function FuncBase(Index: Integer): TtkTokenKind;
    function FuncBool(Index: Integer): TtkTokenKind;
    function FuncBreak(Index: Integer): TtkTokenKind;
    function FuncByte(Index: Integer): TtkTokenKind;
    function FuncCase(Index: Integer): TtkTokenKind;
    function FuncCatch(Index: Integer): TtkTokenKind;
    function FuncChar(Index: Integer): TtkTokenKind;
    function FuncChecked(Index: Integer): TtkTokenKind;
    function FuncClass(Index: Integer): TtkTokenKind;
    function FuncConst(Index: Integer): TtkTokenKind;
    function FuncContinue(Index: Integer): TtkTokenKind;
    function FuncDecimal(Index: Integer): TtkTokenKind;
    function FuncDefault(Index: Integer): TtkTokenKind;
    function FuncDelegate(Index: Integer): TtkTokenKind;
    function FuncDo(Index: Integer): TtkTokenKind;
    function FuncDouble(Index: Integer): TtkTokenKind;
    function FuncElse(Index: Integer): TtkTokenKind;
    function FuncEnum(Index: Integer): TtkTokenKind;
    function FuncEvent(Index: Integer): TtkTokenKind;
    function FuncExplicit(Index: Integer): TtkTokenKind;
    function FuncExtern(Index: Integer): TtkTokenKind;
    function FuncFalse(Index: Integer): TtkTokenKind;
    function FuncFinally(Index: Integer): TtkTokenKind;
    function FuncFixed(Index: Integer): TtkTokenKind;
    function FuncFloat(Index: Integer): TtkTokenKind;
    function FuncFor(Index: Integer): TtkTokenKind;
    function FuncForeach(Index: Integer): TtkTokenKind;
    function FuncGoto(Index: Integer): TtkTokenKind;
    function FuncIf(Index: Integer): TtkTokenKind;
    function FuncImplicit(Index: Integer): TtkTokenKind;
    function FuncIn(Index: Integer): TtkTokenKind;
    function FuncInt(Index: Integer): TtkTokenKind;
    function FuncInterface(Index: Integer): TtkTokenKind;
    function FuncInternal(Index: Integer): TtkTokenKind;
    function FuncIs(Index: Integer): TtkTokenKind;
    function FuncLock(Index: Integer): TtkTokenKind;
    function FuncLong(Index: Integer): TtkTokenKind;
    function FuncNamespace(Index: Integer): TtkTokenKind;
    function FuncNew(Index: Integer): TtkTokenKind;
    function FuncNull(Index: Integer): TtkTokenKind;
    function FuncObject(Index: Integer): TtkTokenKind;
    function FuncOperator(Index: Integer): TtkTokenKind;
    function FuncOut(Index: Integer): TtkTokenKind;
    function FuncOverride(Index: Integer): TtkTokenKind;
    function FuncParams(Index: Integer): TtkTokenKind;
    function FuncPrivate(Index: Integer): TtkTokenKind;
    function FuncProtected(Index: Integer): TtkTokenKind;
    function FuncPublic(Index: Integer): TtkTokenKind;
    function FuncReadonly(Index: Integer): TtkTokenKind;
    function FuncRef(Index: Integer): TtkTokenKind;
    function FuncReturn(Index: Integer): TtkTokenKind;
    function FuncSbyte(Index: Integer): TtkTokenKind;
    function FuncSealed(Index: Integer): TtkTokenKind;
    function FuncSizeof(Index: Integer): TtkTokenKind;
    function FuncStackalloc(Index: Integer): TtkTokenKind;
    function FuncStatic(Index: Integer): TtkTokenKind;
    function FuncString(Index: Integer): TtkTokenKind;
    function FuncStruct(Index: Integer): TtkTokenKind;
    function FuncSwitch(Index: Integer): TtkTokenKind;
    function FuncThis(Index: Integer): TtkTokenKind;
    function FuncThrow(Index: Integer): TtkTokenKind;
    function FuncTrue(Index: Integer): TtkTokenKind;
    function FuncTry(Index: Integer): TtkTokenKind;
    function FuncTypeof(Index: Integer): TtkTokenKind;
    function FuncUint(Index: Integer): TtkTokenKind;
    function FuncUlong(Index: Integer): TtkTokenKind;
    function FuncUnchecked(Index: Integer): TtkTokenKind;
    function FuncUnsafe(Index: Integer): TtkTokenKind;
    function FuncUshort(Index: Integer): TtkTokenKind;
    function FuncUsing(Index: Integer): TtkTokenKind;
    function FuncVirtual(Index: Integer): TtkTokenKind;
    function FuncVoid(Index: Integer): TtkTokenKind;
    function FuncWhile(Index: Integer): TtkTokenKind;
    function HashKey(Str: PWideChar): Cardinal;
    function IdentKind(MayBe: PWideChar): TtkTokenKind;
    procedure InitIdent;
    procedure AnsiCProc;
    procedure AndSymbolProc;
    procedure AsciiCharProc;
    procedure AtSymbolProc;
    procedure BraceCloseProc;
    procedure BraceOpenProc;
    procedure CRProc;
    procedure ColonProc;
    procedure CommaProc;
    procedure DirectiveProc;
    procedure EqualProc;
    procedure GreaterProc;
    procedure IdentProc;
    procedure LFProc;
    procedure LowerProc;
    procedure MinusProc;
    procedure ModSymbolProc;
    procedure NotSymbolProc;
    procedure NullProc;
    procedure NumberProc;
    procedure OrSymbolProc;
    procedure PlusProc;
    procedure PointProc;
    procedure QuestionProc;
    procedure RoundCloseProc;
    procedure RoundOpenProc;
    procedure SemiColonProc;
    procedure SlashProc;
    procedure SpaceProc;
    procedure SquareCloseProc;
    procedure SquareOpenProc;
    procedure StarProc;
    procedure StringProc;
    procedure TildeProc;
    procedure XOrSymbolProc;
    procedure UnknownProc;
    procedure StringEndProc;
  protected
    function GetExtTokenID: TxtkTokenKind;
    function IsFilterStored: Boolean; override;
    function GetSampleSource: UnicodeString; override;
    procedure NextProcedure;
  public
    class function GetCapabilities: TSynHighlighterCapabilities; override;
    class function GetLanguageName: string; override;
    class function GetFriendlyLanguageName: UnicodeString; override;
  public
    constructor Create(AOwner: TComponent); override;
    function GetDefaultAttribute(Index: integer): TSynEdit32HighlighterAttributes;
      override;
    function GetRange: Pointer; override;
    function GetTokenID: TtkTokenKind;
    function GetTokenAttribute: TSynEdit32HighlighterAttributes; override;
    function GetTokenKind: integer; override;
    procedure Next; override;
    procedure SetRange(Value: Pointer); override;
    procedure ResetRange; override;
    function UseUserSettings(settingIndex: integer): boolean; override;
    procedure EnumUserSettings(settings: TStrings); override;
    property ExtTokenID: TxtkTokenKind read GetExtTokenID;
  published
    property AsmAttri: TSynEdit32HighlighterAttributes read FAsmAttri write FAsmAttri;
    property CommentAttri: TSynEdit32HighlighterAttributes read FCommentAttri
      write FCommentAttri;
    property DirecAttri: TSynEdit32HighlighterAttributes read FDirecAttri
      write FDirecAttri;
    property IdentifierAttri: TSynEdit32HighlighterAttributes read FIdentifierAttri
      write FIdentifierAttri;
    property InvalidAttri: TSynEdit32HighlighterAttributes read FInvalidAttri
      write FInvalidAttri;
    property KeyAttri: TSynEdit32HighlighterAttributes read FKeyAttri write FKeyAttri;
    property NumberAttri: TSynEdit32HighlighterAttributes read FNumberAttri
      write FNumberAttri;
    property SpaceAttri: TSynEdit32HighlighterAttributes read FSpaceAttri
      write FSpaceAttri;
    property StringAttri: TSynEdit32HighlighterAttributes read FStringAttri
      write FStringAttri;
    property SymbolAttri: TSynEdit32HighlighterAttributes read FSymbolAttri
      write FSymbolAttri;
  end;

implementation

uses
  Windows, Registry,
  SynEdit32.StrConst;

const
  KeyWords: array[0..74] of UnicodeString = (
    'abstract', 'as', 'base', 'bool', 'break', 'byte', 'case', 'catch', 'char', 
    'checked', 'class', 'const', 'continue', 'decimal', 'default', 'delegate', 
    'do', 'double', 'else', 'enum', 'event', 'explicit', 'extern', 'false', 
    'finally', 'fixed', 'float', 'for', 'foreach', 'goto', 'if', 'implicit', 
    'in', 'int', 'interface', 'internal', 'is', 'lock', 'long', 'namespace', 
    'new', 'null', 'object', 'operator', 'out', 'override', 'params', 'private', 
    'protected', 'public', 'readonly', 'ref', 'return', 'sbyte', 'sealed', 
    'sizeof', 'stackalloc', 'static', 'string', 'struct', 'switch', 'this', 
    'throw', 'true', 'try', 'typeof', 'uint', 'ulong', 'unchecked', 'unsafe', 
    'ushort', 'using', 'virtual', 'void', 'while' 
  );

  KeyIndices: array[0..210] of Integer = (
    71, -1, -1, -1, -1, -1, -1, -1, -1, 69, -1, -1, -1, -1, 1, 46, -1, -1, 62, 
    -1, 53, -1, -1, -1, -1, 3, -1, -1, 18, -1, 8, -1, -1, -1, -1, -1, 19, -1, 
    -1, -1, -1, -1, 45, -1, -1, 28, 44, -1, 47, 21, -1, -1, -1, -1, -1, 73, -1, 
    -1, 9, -1, -1, -1, 26, 49, 63, 65, -1, -1, 16, 67, -1, 59, -1, -1, -1, 66, 
    -1, 50, -1, -1, -1, 29, -1, 32, 37, -1, -1, 48, -1, -1, 55, -1, 14, 40, -1, 
    -1, 13, -1, 12, -1, -1, 15, 30, -1, -1, -1, 41, -1, -1, -1, -1, 4, 56, -1, 
    58, -1, 38, -1, -1, -1, -1, 74, -1, -1, -1, 17, 33, -1, -1, 20, -1, -1, 27, 
    31, -1, 6, -1, -1, -1, -1, 7, -1, -1, 10, -1, -1, 2, -1, -1, -1, 64, -1, -1, 
    43, -1, -1, -1, 0, -1, 34, -1, 25, -1, -1, 5, 61, 60, -1, 42, -1, -1, -1, 
    51, -1, -1, -1, -1, 22, -1, -1, 72, -1, -1, 57, -1, 70, -1, 11, -1, -1, -1, 
    24, -1, 35, -1, -1, 23, -1, 39, -1, -1, 68, 52, 36, -1, -1, -1, -1, 54, -1, 
    -1 
  );

{$Q-}
function TSynEdit32HighlighterCS.HashKey(Str: PWideChar): Cardinal;
begin
  Result := 0;
  while IsIdentChar(Str^) do
  begin
    Result := Result * 723 + Ord(Str^) * 24;
    Inc(Str);
  end;
  Result := Result mod 211;
  FStringLen := Str - FToIdent;
end;
{$Q+}

function TSynEdit32HighlighterCS.IdentKind(MayBe: PWideChar): TtkTokenKind;
var
  Key: Cardinal;
begin
  FToIdent := MayBe;
  Key := HashKey(MayBe);
  if Key <= High(FIdentFuncTable) then
    Result := FIdentFuncTable[Key](KeyIndices[Key])
  else
    Result := tkIdentifier;
end;

procedure TSynEdit32HighlighterCS.InitIdent;
var
  i: Integer;
begin
  for i := Low(FIdentFuncTable) to High(FIdentFuncTable) do
    if KeyIndices[i] = -1 then
      FIdentFuncTable[i] := AltFunc;

  FIdentFuncTable[157] := FuncAbstract;
  FIdentFuncTable[14] := FuncAs;
  FIdentFuncTable[146] := FuncBase;
  FIdentFuncTable[25] := FuncBool;
  FIdentFuncTable[111] := FuncBreak;
  FIdentFuncTable[164] := FuncByte;
  FIdentFuncTable[135] := FuncCase;
  FIdentFuncTable[140] := FuncCatch;
  FIdentFuncTable[30] := FuncChar;
  FIdentFuncTable[58] := FuncChecked;
  FIdentFuncTable[143] := FuncClass;
  FIdentFuncTable[187] := FuncConst;
  FIdentFuncTable[98] := FuncContinue;
  FIdentFuncTable[96] := FuncDecimal;
  FIdentFuncTable[92] := FuncDefault;
  FIdentFuncTable[101] := FuncDelegate;
  FIdentFuncTable[68] := FuncDo;
  FIdentFuncTable[125] := FuncDouble;
  FIdentFuncTable[28] := FuncElse;
  FIdentFuncTable[36] := FuncEnum;
  FIdentFuncTable[129] := FuncEvent;
  FIdentFuncTable[49] := FuncExplicit;
  FIdentFuncTable[177] := FuncExtern;
  FIdentFuncTable[196] := FuncFalse;
  FIdentFuncTable[191] := FuncFinally;
  FIdentFuncTable[161] := FuncFixed;
  FIdentFuncTable[62] := FuncFloat;
  FIdentFuncTable[132] := FuncFor;
  FIdentFuncTable[45] := FuncForeach;
  FIdentFuncTable[81] := FuncGoto;
  FIdentFuncTable[102] := FuncIf;
  FIdentFuncTable[133] := FuncImplicit;
  FIdentFuncTable[83] := FuncIn;
  FIdentFuncTable[126] := FuncInt;
  FIdentFuncTable[159] := FuncInterface;
  FIdentFuncTable[193] := FuncInternal;
  FIdentFuncTable[203] := FuncIs;
  FIdentFuncTable[84] := FuncLock;
  FIdentFuncTable[116] := FuncLong;
  FIdentFuncTable[198] := FuncNamespace;
  FIdentFuncTable[93] := FuncNew;
  FIdentFuncTable[106] := FuncNull;
  FIdentFuncTable[168] := FuncObject;
  FIdentFuncTable[153] := FuncOperator;
  FIdentFuncTable[46] := FuncOut;
  FIdentFuncTable[42] := FuncOverride;
  FIdentFuncTable[15] := FuncParams;
  FIdentFuncTable[48] := FuncPrivate;
  FIdentFuncTable[87] := FuncProtected;
  FIdentFuncTable[63] := FuncPublic;
  FIdentFuncTable[77] := FuncReadonly;
  FIdentFuncTable[172] := FuncRef;
  FIdentFuncTable[202] := FuncReturn;
  FIdentFuncTable[20] := FuncSbyte;
  FIdentFuncTable[208] := FuncSealed;
  FIdentFuncTable[90] := FuncSizeof;
  FIdentFuncTable[112] := FuncStackalloc;
  FIdentFuncTable[183] := FuncStatic;
  FIdentFuncTable[114] := FuncString;
  FIdentFuncTable[71] := FuncStruct;
  FIdentFuncTable[166] := FuncSwitch;
  FIdentFuncTable[165] := FuncThis;
  FIdentFuncTable[18] := FuncThrow;
  FIdentFuncTable[64] := FuncTrue;
  FIdentFuncTable[150] := FuncTry;
  FIdentFuncTable[65] := FuncTypeof;
  FIdentFuncTable[75] := FuncUint;
  FIdentFuncTable[69] := FuncUlong;
  FIdentFuncTable[201] := FuncUnchecked;
  FIdentFuncTable[9] := FuncUnsafe;
  FIdentFuncTable[185] := FuncUshort;
  FIdentFuncTable[0] := FuncUsing;
  FIdentFuncTable[180] := FuncVirtual;
  FIdentFuncTable[55] := FuncVoid;
  FIdentFuncTable[121] := FuncWhile;
end;



function TSynEdit32HighlighterCS.AltFunc(Index: Integer): TtkTokenKind;
begin
  Result := tkIdentifier;
end;

function TSynEdit32HighlighterCS.FuncAbstract(Index: Integer): TtkTokenKind;
begin
  if IsCurrentToken(KeyWords[Index]) then
    Result := tkKey
  else
    Result := tkIdentifier;
end;

function TSynEdit32HighlighterCS.FuncAs(Index: Integer): TtkTokenKind;
begin
  if IsCurrentToken(KeyWords[Index]) then
    Result := tkKey
  else
    Result := tkIdentifier;
end;

function TSynEdit32HighlighterCS.FuncBase(Index: Integer): TtkTokenKind;
begin
  if IsCurrentToken(KeyWords[Index]) then
    Result := tkKey
  else
    Result := tkIdentifier;
end;

function TSynEdit32HighlighterCS.FuncBool(Index: Integer): TtkTokenKind;
begin
  if IsCurrentToken(KeyWords[Index]) then
    Result := tkKey
  else
    Result := tkIdentifier;
end;

function TSynEdit32HighlighterCS.FuncBreak(Index: Integer): TtkTokenKind;
begin
  if IsCurrentToken(KeyWords[Index]) then
    Result := tkKey
  else
    Result := tkIdentifier;
end;

function TSynEdit32HighlighterCS.FuncByte(Index: Integer): TtkTokenKind;
begin
  if IsCurrentToken(KeyWords[Index]) then
    Result := tkKey
  else
    Result := tkIdentifier;
end;

function TSynEdit32HighlighterCS.FuncCase(Index: Integer): TtkTokenKind;
begin
  if IsCurrentToken(KeyWords[Index]) then
    Result := tkKey
  else
    Result := tkIdentifier;
end;

function TSynEdit32HighlighterCS.FuncCatch(Index: Integer): TtkTokenKind;
begin
  if IsCurrentToken(KeyWords[Index]) then
    Result := tkKey
  else
    Result := tkIdentifier;
end;

function TSynEdit32HighlighterCS.FuncChar(Index: Integer): TtkTokenKind;
begin
  if IsCurrentToken(KeyWords[Index]) then
    Result := tkKey
  else
    Result := tkIdentifier;
end;

function TSynEdit32HighlighterCS.FuncChecked(Index: Integer): TtkTokenKind;
begin
  if IsCurrentToken(KeyWords[Index]) then
    Result := tkKey
  else
    Result := tkIdentifier;
end;

function TSynEdit32HighlighterCS.FuncClass(Index: Integer): TtkTokenKind;
begin
  if IsCurrentToken(KeyWords[Index]) then
    Result := tkKey
  else
    Result := tkIdentifier;
end;

function TSynEdit32HighlighterCS.FuncConst(Index: Integer): TtkTokenKind;
begin
  if IsCurrentToken(KeyWords[Index]) then
    Result := tkKey
  else
    Result := tkIdentifier;
end;

function TSynEdit32HighlighterCS.FuncContinue(Index: Integer): TtkTokenKind;
begin
  if IsCurrentToken(KeyWords[Index]) then
    Result := tkKey
  else
    Result := tkIdentifier;
end;

function TSynEdit32HighlighterCS.FuncDecimal(Index: Integer): TtkTokenKind;
begin
  if IsCurrentToken(KeyWords[Index]) then
    Result := tkKey
  else
    Result := tkIdentifier;
end;

function TSynEdit32HighlighterCS.FuncDefault(Index: Integer): TtkTokenKind;
begin
  if IsCurrentToken(KeyWords[Index]) then
    Result := tkKey
  else
    Result := tkIdentifier;
end;

function TSynEdit32HighlighterCS.FuncDelegate(Index: Integer): TtkTokenKind;
begin
  if IsCurrentToken(KeyWords[Index]) then
    Result := tkKey
  else
    Result := tkIdentifier;
end;

function TSynEdit32HighlighterCS.FuncDo(Index: Integer): TtkTokenKind;
begin
  if IsCurrentToken(KeyWords[Index]) then
    Result := tkKey
  else
    Result := tkIdentifier;
end;

function TSynEdit32HighlighterCS.FuncDouble(Index: Integer): TtkTokenKind;
begin
  if IsCurrentToken(KeyWords[Index]) then
    Result := tkKey
  else
    Result := tkIdentifier;
end;

function TSynEdit32HighlighterCS.FuncElse(Index: Integer): TtkTokenKind;
begin
  if IsCurrentToken(KeyWords[Index]) then
    Result := tkKey
  else
    Result := tkIdentifier;
end;

function TSynEdit32HighlighterCS.FuncEnum(Index: Integer): TtkTokenKind;
begin
  if IsCurrentToken(KeyWords[Index]) then
    Result := tkKey
  else
    Result := tkIdentifier;
end;

function TSynEdit32HighlighterCS.FuncEvent(Index: Integer): TtkTokenKind;
begin
  if IsCurrentToken(KeyWords[Index]) then
    Result := tkKey
  else
    Result := tkIdentifier;
end;

function TSynEdit32HighlighterCS.FuncExplicit(Index: Integer): TtkTokenKind;
begin
  if IsCurrentToken(KeyWords[Index]) then
    Result := tkKey
  else
    Result := tkIdentifier;
end;

function TSynEdit32HighlighterCS.FuncExtern(Index: Integer): TtkTokenKind;
begin
  if IsCurrentToken(KeyWords[Index]) then
    Result := tkKey
  else
    Result := tkIdentifier;
end;

function TSynEdit32HighlighterCS.FuncFalse(Index: Integer): TtkTokenKind;
begin
  if IsCurrentToken(KeyWords[Index]) then
    Result := tkKey
  else
    Result := tkIdentifier;
end;

function TSynEdit32HighlighterCS.FuncFinally(Index: Integer): TtkTokenKind;
begin
  if IsCurrentToken(KeyWords[Index]) then
    Result := tkKey
  else
    Result := tkIdentifier;
end;

function TSynEdit32HighlighterCS.FuncFixed(Index: Integer): TtkTokenKind;
begin
  if IsCurrentToken(KeyWords[Index]) then
    Result := tkKey
  else
    Result := tkIdentifier;
end;

function TSynEdit32HighlighterCS.FuncFloat(Index: Integer): TtkTokenKind;
begin
  if IsCurrentToken(KeyWords[Index]) then
    Result := tkKey
  else
    Result := tkIdentifier;
end;

function TSynEdit32HighlighterCS.FuncFor(Index: Integer): TtkTokenKind;
begin
  if IsCurrentToken(KeyWords[Index]) then
    Result := tkKey
  else
    Result := tkIdentifier;
end;

function TSynEdit32HighlighterCS.FuncForeach(Index: Integer): TtkTokenKind;
begin
  if IsCurrentToken(KeyWords[Index]) then
    Result := tkKey
  else
    Result := tkIdentifier;
end;

function TSynEdit32HighlighterCS.FuncGoto(Index: Integer): TtkTokenKind;
begin
  if IsCurrentToken(KeyWords[Index]) then
    Result := tkKey
  else
    Result := tkIdentifier;
end;

function TSynEdit32HighlighterCS.FuncIf(Index: Integer): TtkTokenKind;
begin
  if IsCurrentToken(KeyWords[Index]) then
    Result := tkKey
  else
    Result := tkIdentifier;
end;

function TSynEdit32HighlighterCS.FuncImplicit(Index: Integer): TtkTokenKind;
begin
  if IsCurrentToken(KeyWords[Index]) then
    Result := tkKey
  else
    Result := tkIdentifier;
end;

function TSynEdit32HighlighterCS.FuncIn(Index: Integer): TtkTokenKind;
begin
  if IsCurrentToken(KeyWords[Index]) then
    Result := tkKey
  else
    Result := tkIdentifier;
end;

function TSynEdit32HighlighterCS.FuncInt(Index: Integer): TtkTokenKind;
begin
  if IsCurrentToken(KeyWords[Index]) then
    Result := tkKey
  else
    Result := tkIdentifier;
end;

function TSynEdit32HighlighterCS.FuncInterface(Index: Integer): TtkTokenKind;
begin
  if IsCurrentToken(KeyWords[Index]) then
    Result := tkKey
  else
    Result := tkIdentifier;
end;

function TSynEdit32HighlighterCS.FuncInternal(Index: Integer): TtkTokenKind;
begin
  if IsCurrentToken(KeyWords[Index]) then
    Result := tkKey
  else
    Result := tkIdentifier;
end;

function TSynEdit32HighlighterCS.FuncIs(Index: Integer): TtkTokenKind;
begin
  if IsCurrentToken(KeyWords[Index]) then
    Result := tkKey
  else
    Result := tkIdentifier;
end;

function TSynEdit32HighlighterCS.FuncLock(Index: Integer): TtkTokenKind;
begin
  if IsCurrentToken(KeyWords[Index]) then
    Result := tkKey
  else
    Result := tkIdentifier;
end;

function TSynEdit32HighlighterCS.FuncLong(Index: Integer): TtkTokenKind;
begin
  if IsCurrentToken(KeyWords[Index]) then
    Result := tkKey
  else
    Result := tkIdentifier;
end;

function TSynEdit32HighlighterCS.FuncNamespace(Index: Integer): TtkTokenKind;
begin
  if IsCurrentToken(KeyWords[Index]) then
    Result := tkKey
  else
    Result := tkIdentifier;
end;

function TSynEdit32HighlighterCS.FuncNew(Index: Integer): TtkTokenKind;
begin
  if IsCurrentToken(KeyWords[Index]) then
    Result := tkKey
  else
    Result := tkIdentifier;
end;

function TSynEdit32HighlighterCS.FuncNull(Index: Integer): TtkTokenKind;
begin
  if IsCurrentToken(KeyWords[Index]) then
    Result := tkKey
  else
    Result := tkIdentifier;
end;

function TSynEdit32HighlighterCS.FuncObject(Index: Integer): TtkTokenKind;
begin
  if IsCurrentToken(KeyWords[Index]) then
    Result := tkKey
  else
    Result := tkIdentifier;
end;

function TSynEdit32HighlighterCS.FuncOperator(Index: Integer): TtkTokenKind;
begin
  if IsCurrentToken(KeyWords[Index]) then
    Result := tkKey
  else
    Result := tkIdentifier;
end;

function TSynEdit32HighlighterCS.FuncOut(Index: Integer): TtkTokenKind;
begin
  if IsCurrentToken(KeyWords[Index]) then
    Result := tkKey
  else
    Result := tkIdentifier;
end;

function TSynEdit32HighlighterCS.FuncOverride(Index: Integer): TtkTokenKind;
begin
  if IsCurrentToken(KeyWords[Index]) then
    Result := tkKey
  else
    Result := tkIdentifier;
end;

function TSynEdit32HighlighterCS.FuncParams(Index: Integer): TtkTokenKind;
begin
  if IsCurrentToken(KeyWords[Index]) then
    Result := tkKey
  else
    Result := tkIdentifier;
end;

function TSynEdit32HighlighterCS.FuncPrivate(Index: Integer): TtkTokenKind;
begin
  if IsCurrentToken(KeyWords[Index]) then
    Result := tkKey
  else
    Result := tkIdentifier;
end;

function TSynEdit32HighlighterCS.FuncProtected(Index: Integer): TtkTokenKind;
begin
  if IsCurrentToken(KeyWords[Index]) then
    Result := tkKey
  else
    Result := tkIdentifier;
end;

function TSynEdit32HighlighterCS.FuncPublic(Index: Integer): TtkTokenKind;
begin
  if IsCurrentToken(KeyWords[Index]) then
    Result := tkKey
  else
    Result := tkIdentifier;
end;

function TSynEdit32HighlighterCS.FuncReadonly(Index: Integer): TtkTokenKind;
begin
  if IsCurrentToken(KeyWords[Index]) then
    Result := tkKey
  else
    Result := tkIdentifier;
end;

function TSynEdit32HighlighterCS.FuncRef(Index: Integer): TtkTokenKind;
begin
  if IsCurrentToken(KeyWords[Index]) then
    Result := tkKey
  else
    Result := tkIdentifier;
end;

function TSynEdit32HighlighterCS.FuncReturn(Index: Integer): TtkTokenKind;
begin
  if IsCurrentToken(KeyWords[Index]) then
    Result := tkKey
  else
    Result := tkIdentifier;
end;

function TSynEdit32HighlighterCS.FuncSbyte(Index: Integer): TtkTokenKind;
begin
  if IsCurrentToken(KeyWords[Index]) then
    Result := tkKey
  else
    Result := tkIdentifier;
end;

function TSynEdit32HighlighterCS.FuncSealed(Index: Integer): TtkTokenKind;
begin
  if IsCurrentToken(KeyWords[Index]) then
    Result := tkKey
  else
    Result := tkIdentifier;
end;

function TSynEdit32HighlighterCS.FuncSizeof(Index: Integer): TtkTokenKind;
begin
  if IsCurrentToken(KeyWords[Index]) then
    Result := tkKey
  else
    Result := tkIdentifier;
end;

function TSynEdit32HighlighterCS.FuncStackalloc(Index: Integer): TtkTokenKind;
begin
  if IsCurrentToken(KeyWords[Index]) then
    Result := tkKey
  else
    Result := tkIdentifier;
end;

function TSynEdit32HighlighterCS.FuncStatic(Index: Integer): TtkTokenKind;
begin
  if IsCurrentToken(KeyWords[Index]) then
    Result := tkKey
  else
    Result := tkIdentifier;
end;

function TSynEdit32HighlighterCS.FuncString(Index: Integer): TtkTokenKind;
begin
  if IsCurrentToken(KeyWords[Index]) then
    Result := tkKey
  else
    Result := tkIdentifier;
end;

function TSynEdit32HighlighterCS.FuncStruct(Index: Integer): TtkTokenKind;
begin
  if IsCurrentToken(KeyWords[Index]) then
    Result := tkKey
  else
    Result := tkIdentifier;
end;

function TSynEdit32HighlighterCS.FuncSwitch(Index: Integer): TtkTokenKind;
begin
  if IsCurrentToken(KeyWords[Index]) then
    Result := tkKey
  else
    Result := tkIdentifier;
end;

function TSynEdit32HighlighterCS.FuncThis(Index: Integer): TtkTokenKind;
begin
  if IsCurrentToken(KeyWords[Index]) then
    Result := tkKey
  else
    Result := tkIdentifier;
end;

function TSynEdit32HighlighterCS.FuncThrow(Index: Integer): TtkTokenKind;
begin
  if IsCurrentToken(KeyWords[Index]) then
    Result := tkKey
  else
    Result := tkIdentifier;
end;

function TSynEdit32HighlighterCS.FuncTrue(Index: Integer): TtkTokenKind;
begin
  if IsCurrentToken(KeyWords[Index]) then
    Result := tkKey
  else
    Result := tkIdentifier;
end;

function TSynEdit32HighlighterCS.FuncTry(Index: Integer): TtkTokenKind;
begin
  if IsCurrentToken(KeyWords[Index]) then
    Result := tkKey
  else
    Result := tkIdentifier;
end;

function TSynEdit32HighlighterCS.FuncTypeof(Index: Integer): TtkTokenKind;
begin
  if IsCurrentToken(KeyWords[Index]) then
    Result := tkKey
  else
    Result := tkIdentifier;
end;

function TSynEdit32HighlighterCS.FuncUint(Index: Integer): TtkTokenKind;
begin
  if IsCurrentToken(KeyWords[Index]) then
    Result := tkKey
  else
    Result := tkIdentifier;
end;

function TSynEdit32HighlighterCS.FuncUlong(Index: Integer): TtkTokenKind;
begin
  if IsCurrentToken(KeyWords[Index]) then
    Result := tkKey
  else
    Result := tkIdentifier;
end;

function TSynEdit32HighlighterCS.FuncUnchecked(Index: Integer): TtkTokenKind;
begin
  if IsCurrentToken(KeyWords[Index]) then
    Result := tkKey
  else
    Result := tkIdentifier;
end;

function TSynEdit32HighlighterCS.FuncUnsafe(Index: Integer): TtkTokenKind;
begin
  if IsCurrentToken(KeyWords[Index]) then
    Result := tkKey
  else
    Result := tkIdentifier;
end;

function TSynEdit32HighlighterCS.FuncUshort(Index: Integer): TtkTokenKind;
begin
  if IsCurrentToken(KeyWords[Index]) then
    Result := tkKey
  else
    Result := tkIdentifier;
end;

function TSynEdit32HighlighterCS.FuncUsing(Index: Integer): TtkTokenKind;
begin
  if IsCurrentToken(KeyWords[Index]) then
    Result := tkKey
  else
    Result := tkIdentifier;
end;

function TSynEdit32HighlighterCS.FuncVirtual(Index: Integer): TtkTokenKind;
begin
  if IsCurrentToken(KeyWords[Index]) then
    Result := tkKey
  else
    Result := tkIdentifier;
end;

function TSynEdit32HighlighterCS.FuncVoid(Index: Integer): TtkTokenKind;
begin
  if IsCurrentToken(KeyWords[Index]) then
    Result := tkKey
  else
    Result := tkIdentifier;
end;

function TSynEdit32HighlighterCS.FuncWhile(Index: Integer): TtkTokenKind;
begin
  if IsCurrentToken(KeyWords[Index]) then
    Result := tkKey
  else
    Result := tkIdentifier;
end;

constructor TSynEdit32HighlighterCS.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

  FCaseSensitive := True;

  FAsmAttri := TSynEdit32HighlighterAttributes.Create(SYNS_AttrAssembler, SYNS_FriendlyAttrAssembler);
  AddAttribute(FAsmAttri);
  FCommentAttri := TSynEdit32HighlighterAttributes.Create(SYNS_AttrComment, SYNS_FriendlyAttrComment);
  FCommentAttri.Style:= [fsItalic];
  AddAttribute(FCommentAttri);
  FIdentifierAttri := TSynEdit32HighlighterAttributes.Create(SYNS_AttrIdentifier, SYNS_FriendlyAttrIdentifier);
  AddAttribute(FIdentifierAttri);
  FInvalidAttri := TSynEdit32HighlighterAttributes.Create(SYNS_AttrIllegalChar, SYNS_FriendlyAttrIllegalChar);
  AddAttribute(FInvalidAttri);
  FKeyAttri := TSynEdit32HighlighterAttributes.Create(SYNS_AttrReservedWord, SYNS_FriendlyAttrReservedWord);
  FKeyAttri.Style:= [fsBold];
  AddAttribute(FKeyAttri);
  FNumberAttri := TSynEdit32HighlighterAttributes.Create(SYNS_AttrNumber, SYNS_FriendlyAttrNumber);
  AddAttribute(FNumberAttri);
  FSpaceAttri := TSynEdit32HighlighterAttributes.Create(SYNS_AttrSpace, SYNS_FriendlyAttrSpace);
  AddAttribute(FSpaceAttri);
  FStringAttri := TSynEdit32HighlighterAttributes.Create(SYNS_AttrString, SYNS_FriendlyAttrString);
  AddAttribute(FStringAttri);
  FSymbolAttri := TSynEdit32HighlighterAttributes.Create(SYNS_AttrSymbol, SYNS_FriendlyAttrSymbol);
  AddAttribute(FSymbolAttri);
  FDirecAttri := TSynEdit32HighlighterAttributes.Create(SYNS_AttrPreprocessor, SYNS_FriendlyAttrPreprocessor);
  AddAttribute(FDirecAttri);
  SetAttributesOnChange(DefHighlightChange);
  InitIdent;
  FRange := rsUnknown;
  FAsmStart := False;
  fDefaultFilter := SYNS_FilterCS;
end; { Create }

procedure TSynEdit32HighlighterCS.AnsiCProc;
begin
  FTokenID := tkComment;
  case FLine[FRun] of
    #0:
      begin
        NullProc;
        Exit;
      end;
    #10:
      begin
        LFProc;
        Exit;
      end;
    #13:
      begin
        CRProc;
        Exit;
      end;
  end;

  while FLine[FRun] <> #0 do
    case FLine[FRun] of
      '*':
        if FLine[FRun + 1] = '/' then
        begin
          Inc(FRun, 2);
          if FRange = rsAnsiCAsm then
            FRange := rsAsm
          else if FRange = rsAnsiCAsmBlock then
            FRange := rsAsmBlock
          else if FRange = rsDirectiveComment then
            FRange := rsDirective
          else
            FRange := rsUnKnown;
          Break;
        end else
          Inc(FRun);
      #10: Break;
      #13: Break;
    else Inc(FRun);
    end;
end;

procedure TSynEdit32HighlighterCS.AndSymbolProc;
begin
  FTokenID := tkSymbol;
  case FLine[FRun + 1] of
    '=':                               {and assign}
      begin
        Inc(FRun, 2);
        FExtTokenID := xtkAndAssign;
      end;
    '&':                               {logical and}
      begin
        Inc(FRun, 2);
        FExtTokenID := xtkLogAnd;
      end;
  else                                 {and}
    begin
      Inc(FRun);
      FExtTokenID := xtkAnd;
    end;
  end;
end;

procedure TSynEdit32HighlighterCS.AsciiCharProc;
begin
  FTokenID := tkString;
  repeat
    if FLine[FRun] = '\' then
    begin
      if CharInSet(FLine[FRun + 1], [#39, '\']) then
        Inc(FRun);
    end;
    Inc(FRun);
  until IsLineEnd(FRun) or (FLine[FRun] = #39);
  if FLine[FRun] = #39 then
    Inc(FRun);
end;

procedure TSynEdit32HighlighterCS.AtSymbolProc;
begin
  FTokenID := tkUnknown;
  Inc(FRun);
end;

procedure TSynEdit32HighlighterCS.BraceCloseProc;
begin
  Inc(FRun);
  FTokenID := tkSymbol;
  FExtTokenID := xtkBraceClose;
  if FRange = rsAsmBlock then FRange := rsUnknown;
end;

procedure TSynEdit32HighlighterCS.BraceOpenProc;
begin
  Inc(FRun);
  FTokenID := tkSymbol;
  FExtTokenID := xtkBraceOpen;
  if FRange = rsAsm then
  begin
    FRange := rsAsmBlock;
    FAsmStart := True;
  end;
end;

procedure TSynEdit32HighlighterCS.CRProc;
begin
  FTokenID := tkSpace;
  Inc(FRun);
  if FLine[FRun + 1] = #10 then Inc(FRun);
end;

procedure TSynEdit32HighlighterCS.ColonProc;
begin
  FTokenID := tkSymbol;
  case FLine[FRun + 1] of
    ':':                               {scope resolution operator}
      begin
        Inc(FRun, 2);
        FExtTokenID := xtkScopeResolution;
      end;
  else                                 {colon}
    begin
      Inc(FRun);
      FExtTokenID := xtkColon;
    end;
  end;
end;

procedure TSynEdit32HighlighterCS.CommaProc;
begin
  Inc(FRun);
  FTokenID := tkSymbol;
  FExtTokenID := xtkComma;
end;

procedure TSynEdit32HighlighterCS.DirectiveProc;
begin
  if IsLineEnd(FRun) then
  begin
    if (FRun <= 0) or (FLine[FRun - 1] <> '\') then
      FRange := rsUnknown;
    NextProcedure;
  end
  else
  begin
    FTokenID := tkDirective;
    while True do
      case FLine[FRun] of
        '/': // comment?
          begin
            if FLine[FRun + 1] = '/' then
            begin // is end of directive as well
              FRange := rsUnknown;
              Break;
            end else if FLine[FRun + 1] = '*' then
            begin // might be embedded only
              FRange := rsDirectiveComment;
              Break;
            end else
              Inc(FRun);
          end;
        '\': // directive continued on next line?
          begin
            Inc(FRun);
            if IsLineEnd(FRun) then
            begin
              FRange := rsDirective;
              Break;
            end;
          end;
        #0, #10, #13:
          begin
            FRange := rsUnknown;
            Break;
          end;
        else
          Inc(FRun);
      end;
  end;
end;

procedure TSynEdit32HighlighterCS.EqualProc;
begin
  FTokenID := tkSymbol;
  case FLine[FRun + 1] of
    '=':                               {logical equal}
      begin
        Inc(FRun, 2);
        FExtTokenID := xtkLogEqual;
      end;
  else                                 {assign}
    begin
      Inc(FRun);
      FExtTokenID := xtkAssign;
    end;
  end;
end;

procedure TSynEdit32HighlighterCS.GreaterProc;
begin
  FTokenID := tkSymbol;
  case FLine[FRun + 1] of
    '=':                               {greater than or equal to}
      begin
        Inc(FRun, 2);
        FExtTokenID := xtkGreaterThanEqual;
      end;
    '>':
      begin
        if FLine[FRun + 2] = '=' then   {shift right assign}
        begin
          Inc(FRun, 3);
          FExtTokenID := xtkShiftRightAssign;
        end
        else                           {shift right}
        begin
          Inc(FRun, 2);
          FExtTokenID := xtkShiftRight;
        end;
      end;
  else                                 {greater than}
    begin
      Inc(FRun);
      FExtTokenID := xtkGreaterThan;
    end;
  end;
end;

procedure TSynEdit32HighlighterCS.QuestionProc;
begin
  FTokenID := tkSymbol;                {conditional}
  FExtTokenID := xtkQuestion;
  Inc(FRun);
end;

procedure TSynEdit32HighlighterCS.IdentProc;
begin
  FTokenID := IdentKind((FLine + FRun));
  Inc(FRun, FStringLen);
  while IsIdentChar(FLine[FRun]) do Inc(FRun);
end;

procedure TSynEdit32HighlighterCS.LFProc;
begin
  FTokenID := tkSpace;
  Inc(FRun);
end;

procedure TSynEdit32HighlighterCS.LowerProc;
begin
  FTokenID := tkSymbol;
  case FLine[FRun + 1] of
    '=':                               {less than or equal to}
      begin
        Inc(FRun, 2);
        FExtTokenID := xtkLessThanEqual;
      end;
    '<':
      begin
        if FLine[FRun + 2] = '=' then   {shift left assign}
        begin
          Inc(FRun, 3);
          FExtTokenID := xtkShiftLeftAssign;
        end
        else                           {shift left}
        begin
          Inc(FRun, 2);
          FExtTokenID := xtkShiftLeft;
        end;
      end;
  else                                 {less than}
    begin
      Inc(FRun);
      FExtTokenID := xtkLessThan;
    end;
  end;
end;

procedure TSynEdit32HighlighterCS.MinusProc;
begin
  FTokenID := tkSymbol;
  case FLine[FRun + 1] of
    '=':                               {subtract assign}
      begin
        Inc(FRun, 2);
        FExtTokenID := xtkSubtractAssign;
      end;
    '-':                               {decrement}
      begin
        Inc(FRun, 2);
        FExtTokenID := xtkDecrement;
      end;
    '>':                               {arrow}
      begin
        Inc(FRun, 2);
        FExtTokenID := xtkArrow;
      end;
  else                                 {subtract}
    begin
      Inc(FRun);
      FExtTokenID := xtkSubtract;
    end;
  end;
end;

procedure TSynEdit32HighlighterCS.ModSymbolProc;
begin
  FTokenID := tkSymbol;
  case FLine[FRun + 1] of
    '=':                               {mod assign}
      begin
        Inc(FRun, 2);
        FExtTokenID := xtkModAssign;
      end;
  else                                 {mod}
    begin
      Inc(FRun);
      FExtTokenID := xtkMod;
    end;
  end;
end;

procedure TSynEdit32HighlighterCS.NotSymbolProc;
begin
  FTokenID := tkSymbol;
  case FLine[FRun + 1] of
    '=':                               {not equal}
      begin
        Inc(FRun, 2);
        FExtTokenID := xtkNotEqual;
      end;
  else                                 {not}
    begin
      Inc(FRun);
      FExtTokenID := xtkLogComplement;
    end;
  end;
end;

procedure TSynEdit32HighlighterCS.NullProc;
begin
  FTokenID := tkNull;
  Inc(FRun);
end;

procedure TSynEdit32HighlighterCS.NumberProc;

  function IsNumberChar: Boolean;
  begin
    case FLine[FRun] of
      '0'..'9', 'A'..'F', 'a'..'f', '.', 'u', 'U', 'l', 'L', 'x', 'X':
        Result := True;
      else
        Result := False;
    end;
  end;

begin
  Inc(FRun);
  FTokenID := tkNumber;
  while IsNumberChar do
  begin
    case FLine[FRun] of
      '.':
        if FLine[FRun + 1] = '.' then Break;
    end;
    Inc(FRun);
  end;
end;

procedure TSynEdit32HighlighterCS.OrSymbolProc;
begin
  FTokenID := tkSymbol;
  case FLine[FRun + 1] of
    '=':                               {or assign}
      begin
        Inc(FRun, 2);
        FExtTokenID := xtkIncOrAssign;
      end;
    '|':                               {logical or}
      begin
        Inc(FRun, 2);
        FExtTokenID := xtkLogOr;
      end;
  else                                 {or}
    begin
      Inc(FRun);
      FExtTokenID := xtkIncOr;
    end;
  end;
end;

procedure TSynEdit32HighlighterCS.PlusProc;
begin
  FTokenID := tkSymbol;
  case FLine[FRun + 1] of
    '=':                               {add assign}
      begin
        Inc(FRun, 2);
        FExtTokenID := xtkAddAssign;
      end;
    '+':                               {increment}
      begin
        Inc(FRun, 2);
        FExtTokenID := xtkIncrement;
      end;
  else                                 {add}
    begin
      Inc(FRun);
      FExtTokenID := xtkAdd;
    end;
  end;
end;

procedure TSynEdit32HighlighterCS.PointProc;
begin
  FTokenID := tkSymbol;
  if (FLine[FRun + 1] = '.') and (FLine[FRun + 2] = '.') then
    begin                              {ellipse}
      Inc(FRun, 3);
      FExtTokenID := xtkEllipse;
    end
  else                                 {point}
    begin
      Inc(FRun);
      FExtTokenID := xtkPoint;
    end;
end;

procedure TSynEdit32HighlighterCS.RoundCloseProc;
begin
  Inc(FRun);
  FTokenID := tkSymbol;
  FExtTokenID := xtkRoundClose;
end;

procedure TSynEdit32HighlighterCS.RoundOpenProc;
begin
  Inc(FRun);
  FTokenID := tkSymbol;
  FExtTokenID := xtkRoundOpen;
end;

procedure TSynEdit32HighlighterCS.SemiColonProc;
begin
  Inc(FRun);
  FTokenID := tkSymbol;
  FExtTokenID := xtkSemiColon;
  if FRange = rsAsm then FRange := rsUnknown;
end;

procedure TSynEdit32HighlighterCS.SlashProc;
begin
  case FLine[FRun + 1] of
    '/':                               {c++ style comments}
      begin
        FTokenID := tkComment;
        Inc(FRun, 2);
        while not IsLineEnd(FRun) do Inc(FRun);
      end;
    '*':                               {c style comments}
      begin
        FTokenID := tkComment;
        if FRange = rsAsm then
          FRange := rsAnsiCAsm
        else if FRange = rsAsmBlock then
          FRange := rsAnsiCAsmBlock
        else if FRange <> rsDirectiveComment then
          FRange := rsAnsiC;
        Inc(FRun, 2);
        while FLine[FRun] <> #0 do
          case FLine[FRun] of
            '*':
              if FLine[FRun + 1] = '/' then
              begin
                Inc(FRun, 2);
                if FRange = rsDirectiveComment then
                  FRange := rsDirective
                else if FRange = rsAnsiCAsm then
                  FRange := rsAsm
                else
                  begin
                  if FRange = rsAnsiCAsmBlock then
                    FRange := rsAsmBlock
                  else
                    FRange := rsUnKnown;
                  end;
                Break;
              end else Inc(FRun);
            #10, #13:
              begin
                if FRange = rsDirectiveComment then
                  FRange := rsAnsiC;
                Break;
              end;
          else Inc(FRun);
          end;
      end;
    '=':                               {divide assign}
      begin
        Inc(FRun, 2);
        FTokenID := tkSymbol;
        FExtTokenID := xtkDivideAssign;
      end;
  else                                 {divide}
    begin
      Inc(FRun);
      FTokenID := tkSymbol;
      FExtTokenID := xtkDivide;
    end;
  end;
end;

procedure TSynEdit32HighlighterCS.SpaceProc;
begin
  Inc(FRun);
  FTokenID := tkSpace;
  while (FLine[FRun] <= #32) and not IsLineEnd(FRun) do Inc(FRun);
end;

procedure TSynEdit32HighlighterCS.SquareCloseProc;
begin
  Inc(FRun);
  FTokenID := tkSymbol;
  FExtTokenID := xtkSquareClose;
end;

procedure TSynEdit32HighlighterCS.SquareOpenProc;
begin
  Inc(FRun);
  FTokenID := tkSymbol;
  FExtTokenID := xtkSquareOpen;
end;

procedure TSynEdit32HighlighterCS.StarProc;
begin
  FTokenID := tkSymbol;
  case FLine[FRun + 1] of
    '=':                               {multiply assign}
      begin
        Inc(FRun, 2);
        FExtTokenID := xtkMultiplyAssign;
      end;
  else                                 {star}
    begin
      Inc(FRun);
      FExtTokenID := xtkStar;
    end;
  end;
end;

procedure TSynEdit32HighlighterCS.StringProc;
begin
  FTokenID := tkString;
  repeat
    if FLine[FRun] = '\' then
    begin
      case FLine[FRun + 1] of
        #34, '\':
          Inc(FRun);
        #00:
          begin
            Inc(FRun);
            FRange := rsMultilineString;
            Exit;
          end;
      end;
    end;
    Inc(FRun);
  until IsLineEnd(FRun) or (FLine[FRun] = #34);
  if FLine[FRun] = #34 then
    Inc(FRun);
end;

procedure TSynEdit32HighlighterCS.StringEndProc;
begin
  FTokenID := tkString;

  case FLine[FRun] of
    #0:
      begin
        NullProc;
        Exit;
      end;
    #10:
      begin
        LFProc;
        Exit;
      end;
    #13:
      begin
        CRProc;
        Exit;
      end;
  end;

  FRange := rsUnknown;

  repeat
    case FLine[FRun] of
      #0, #10, #13: Break;
      '\':
        begin
          case FLine[FRun + 1] of
            #34, '\':
              Inc(FRun);
            #00:
              begin
                Inc(FRun);
                FRange := rsMultilineString;
                Exit;
              end;
          end;
        end;
      #34: Break;
    end;
    Inc(FRun);
  until IsLineEnd(FRun) or (FLine[FRun] = #34);
  if FLine[FRun] = #34 then
    Inc(FRun);
end;

procedure TSynEdit32HighlighterCS.TildeProc;
begin
  Inc(FRun);                            {bitwise complement}
  FTokenID := tkSymbol;
  FExtTokenID := xtkBitComplement;
end;

procedure TSynEdit32HighlighterCS.XOrSymbolProc;
begin
  FTokenID := tkSymbol;
  case FLine[FRun + 1] of
  	'=':                               {xor assign}
      begin
        Inc(FRun, 2);
        FExtTokenID := xtkXorAssign;
      end;
  else                                 {xor}
    begin
      Inc(FRun);
      FExtTokenID := xtkXor;
    end;
  end;
end;

procedure TSynEdit32HighlighterCS.UnknownProc;
begin
  Inc(FRun);
  FTokenID := tkUnknown;
end;

procedure TSynEdit32HighlighterCS.Next;
begin
  FAsmStart := False;
  fTokenPos := FRun;
  case FRange of
    rsAnsiC, rsAnsiCAsm,
    rsAnsiCAsmBlock, rsDirectiveComment: AnsiCProc;
    rsDirective: DirectiveProc;
    rsMultilineString: StringEndProc;
  else
    begin
      FRange := rsUnknown;
      NextProcedure;
    end;
  end;
  inherited;
end;

procedure TSynEdit32HighlighterCS.NextProcedure;
begin
  case FLine[FRun] of
    '&': AndSymbolProc;
    #39: AsciiCharProc;
    '@': AtSymbolProc;
    '}': BraceCloseProc;
    '{': BraceOpenProc;
    #13: CRProc;
    ':': ColonProc;
    ',': CommaProc;
    '#': DirectiveProc;
    '=': EqualProc;
    '>': GreaterProc;
    '?': QuestionProc;
    'A'..'Z', 'a'..'z', '_': IdentProc;
    #10: LFProc;
    '<': LowerProc;
    '-': MinusProc;
    '%': ModSymbolProc;
    '!': NotSymbolProc;
    #0: NullProc;
    '0'..'9': NumberProc;
    '|': OrSymbolProc;
    '+': PlusProc;
    '.': PointProc;
    ')': RoundCloseProc;
    '(': RoundOpenProc;
    ';': SemiColonProc;
    '/': SlashProc;
    #1..#9, #11, #12, #14..#32: SpaceProc;
    ']': SquareCloseProc;
    '[': SquareOpenProc;
    '*': StarProc;
    #34: StringProc;
    '~': TildeProc;
    '^': XOrSymbolProc;
    else UnknownProc;
  end;
end;

function TSynEdit32HighlighterCS.GetDefaultAttribute(Index: integer): TSynEdit32HighlighterAttributes;
begin
  case Index of
    SYN_ATTR_COMMENT: Result := FCommentAttri;
    SYN_ATTR_IDENTIFIER: Result := FIdentifierAttri;
    SYN_ATTR_KEYWORD: Result := FKeyAttri;
    SYN_ATTR_STRING: Result := FStringAttri;
    SYN_ATTR_WHITESPACE: Result := FSpaceAttri;
    else Result := nil;
  end;
end;

function TSynEdit32HighlighterCS.GetRange: Pointer;
begin
  Result := Pointer(FRange);
end;

function TSynEdit32HighlighterCS.GetTokenID: TtkTokenKind;
begin
  Result := FTokenID;
  if ((FRange = rsAsm) or (FRange = rsAsmBlock)) and not FAsmStart
    and not (FTokenID in [tkComment, tkSpace, tkNull])
  then
    Result := tkAsm;
end;

function TSynEdit32HighlighterCS.GetExtTokenID: TxtkTokenKind;
begin
  Result := FExtTokenID;
end;

function TSynEdit32HighlighterCS.GetTokenAttribute: TSynEdit32HighlighterAttributes;
begin
  case FTokenID of
    tkAsm: Result := FAsmAttri;
    tkComment: Result := FCommentAttri;
    tkDirective: Result := FDirecAttri;
    tkIdentifier: Result := FIdentifierAttri;
    tkKey: Result := FKeyAttri;
    tkNumber: Result := FNumberAttri;
    tkSpace: Result := FSpaceAttri;
    tkString: Result := FStringAttri;
    tkSymbol: Result := FSymbolAttri;
    tkUnknown: Result := FInvalidAttri;
    else Result := nil;
  end;
end;

function TSynEdit32HighlighterCS.GetTokenKind: integer;
begin
  Result := Ord(GetTokenID);
end;

procedure TSynEdit32HighlighterCS.ResetRange;
begin
  FRange:= rsUnknown;
end;

procedure TSynEdit32HighlighterCS.SetRange(Value: Pointer);
begin
  FRange := TRangeState(Value);
end;

procedure TSynEdit32HighlighterCS.EnumUserSettings(settings: TStrings);
begin
  { returns the user settings that exist in the registry }
  with TRegistry.Create do
  begin
    try
      RootKey := HKEY_LOCAL_MACHINE;
      if OpenKeyReadOnly('\SOFTWARE\Borland\C++Builder') then
      begin
        try
          GetKeyNames(settings);
        finally
          CloseKey;
        end;
      end;
    finally
      Free;
    end;
  end;
end;

function TSynEdit32HighlighterCS.UseUserSettings(settingIndex: integer): boolean;
// Possible parameter values:
//   index into TStrings returned by EnumUserSettings
// Possible return values:
//   true : settings were read and used
//   false: problem reading settings or invalid version specified - old settings
//          were preserved

  {$IFNDEF SYN_CLX}
  function ReadCPPBSettings(settingIndex: integer): boolean;

    function ReadCPPBSetting(settingTag: string; attri: TSynEdit32HighlighterAttributes; key: string): boolean;

      function ReadCPPB1(settingTag: string; attri: TSynEdit32HighlighterAttributes; name: string): boolean;
      var
        i: integer;
      begin
        for i := 1 to Length(name) do
          if name[i] = ' ' then name[i] := '_';
        Result := attri.LoadFromBorlandRegistry(HKEY_CURRENT_USER,
             '\SOFTWARE\Borland\C++Builder\'+settingTag+'\Highlight',name,true);
      end; { ReadCPPB1 }

      function ReadCPPB3OrMore(settingTag: string; attri: TSynEdit32HighlighterAttributes; key: string): boolean;
      begin
        Result := attri.LoadFromBorlandRegistry(HKEY_CURRENT_USER,
                 '\Software\Borland\C++Builder\'+settingTag+'\Editor\Highlight',
                 key,false);
      end; { ReadCPPB3OrMore }

    begin { ReadCPPBSetting }
      try
        if (settingTag[1] = '1')
          then Result := ReadCPPB1(settingTag,attri,key)
          else Result := ReadCPPB3OrMore(settingTag,attri,key);
      except Result := false; end;
    end; { ReadCPPBSetting }

  var
    tmpStringAttri    : TSynEdit32HighlighterAttributes;
    tmpNumberAttri    : TSynEdit32HighlighterAttributes;
    tmpKeyAttri       : TSynEdit32HighlighterAttributes;
    tmpSymbolAttri    : TSynEdit32HighlighterAttributes;
    tmpAsmAttri       : TSynEdit32HighlighterAttributes;
    tmpCommentAttri   : TSynEdit32HighlighterAttributes;
    tmpIdentifierAttri: TSynEdit32HighlighterAttributes;
    tmpInvalidAttri   : TSynEdit32HighlighterAttributes;
    tmpSpaceAttri     : TSynEdit32HighlighterAttributes;
    tmpDirecAttri     : TSynEdit32HighlighterAttributes;
    s                 : TStringList;

  begin { ReadCPPBSettings }
    s := TStringList.Create;
    try
      EnumUserSettings(s);
      if settingIndex >= s.Count then
        Result := false
      else
      begin
        tmpStringAttri    := TSynEdit32HighlighterAttributes.Create('', '');
        tmpNumberAttri    := TSynEdit32HighlighterAttributes.Create('', '');
        tmpKeyAttri       := TSynEdit32HighlighterAttributes.Create('', '');
        tmpSymbolAttri    := TSynEdit32HighlighterAttributes.Create('', '');
        tmpAsmAttri       := TSynEdit32HighlighterAttributes.Create('', '');
        tmpCommentAttri   := TSynEdit32HighlighterAttributes.Create('', '');
        tmpIdentifierAttri:= TSynEdit32HighlighterAttributes.Create('', '');
        tmpInvalidAttri   := TSynEdit32HighlighterAttributes.Create('', '');
        tmpSpaceAttri     := TSynEdit32HighlighterAttributes.Create('', '');
        tmpDirecAttri     := TSynEdit32HighlighterAttributes.Create('', '');
        tmpStringAttri    .Assign(FStringAttri);
        tmpNumberAttri    .Assign(FNumberAttri);
        tmpKeyAttri       .Assign(FKeyAttri);
        tmpSymbolAttri    .Assign(FSymbolAttri);
        tmpAsmAttri       .Assign(FAsmAttri);
        tmpCommentAttri   .Assign(FCommentAttri);
        tmpIdentifierAttri.Assign(FIdentifierAttri);
        tmpInvalidAttri   .Assign(FInvalidAttri);
        tmpSpaceAttri     .Assign(FSpaceAttri);
        tmpDirecAttri     .Assign(FDirecAttri);
        if s[settingIndex][1] = '1'
          then Result := ReadCPPBSetting(s[settingIndex],FAsmAttri,'Plain text')
          else Result := ReadCPPBSetting(s[settingIndex],FAsmAttri,'Assembler');
        Result := Result                                                         and
                  ReadCPPBSetting(s[settingIndex],FCommentAttri,'Comment')       and
                  ReadCPPBSetting(s[settingIndex],FIdentifierAttri,'Identifier') and
                  ReadCPPBSetting(s[settingIndex],FInvalidAttri,'Illegal Char')  and
                  ReadCPPBSetting(s[settingIndex],FKeyAttri,'Reserved word')     and
                  ReadCPPBSetting(s[settingIndex],FNumberAttri,'Integer')        and
                  ReadCPPBSetting(s[settingIndex],FSpaceAttri,'Whitespace')      and
                  ReadCPPBSetting(s[settingIndex],FStringAttri,'String')         and
                  ReadCPPBSetting(s[settingIndex],FSymbolAttri,'Symbol')         and
                  ReadCPPBSetting(s[settingIndex],FDirecAttri,'Preprocessor');
        if not Result then
        begin
          FStringAttri    .Assign(tmpStringAttri);
          FNumberAttri    .Assign(tmpNumberAttri);
          FKeyAttri       .Assign(tmpKeyAttri);
          FSymbolAttri    .Assign(tmpSymbolAttri);
          FAsmAttri       .Assign(tmpAsmAttri);
          FCommentAttri   .Assign(tmpCommentAttri);
          FIdentifierAttri.Assign(tmpIdentifierAttri);
          FInvalidAttri.Assign(tmpInvalidAttri);
          FSpaceAttri     .Assign(tmpSpaceAttri);
          FDirecAttri     .Assign(tmpDirecAttri);
        end;
        tmpStringAttri    .Free;
        tmpNumberAttri    .Free;
        tmpKeyAttri       .Free;
        tmpSymbolAttri    .Free;
        tmpAsmAttri       .Free;
        tmpCommentAttri   .Free;
        tmpIdentifierAttri.Free;
        tmpInvalidAttri   .Free;
        tmpSpaceAttri     .Free;
        tmpDirecAttri     .Free;
      end;
    finally s.Free; end;
  end; { ReadCPPBSettings }
  {$ENDIF}

begin
  {$IFNDEF SYN_CLX}
  Result := ReadCPPBSettings(settingIndex);
  {$ELSE}
  Result := False;
  {$ENDIF}
end; { TSynEdit32HighlighterCS.UseUserSettings }

function TSynEdit32HighlighterCS.GetSampleSource: UnicodeString;
begin
  Result := '/* Syntax Highlighting */'#13#10 +
				'int num = 12345;'#13#10 +
				'string str = "Hello World";'#13#10;

end; { GetSampleSource }

class function TSynEdit32HighlighterCS.GetLanguageName: string;
begin
  Result := SYNS_LangCS;
end;

function TSynEdit32HighlighterCS.IsFilterStored: boolean;
begin
  Result := fDefaultFilter <> SYNS_FilterCS;
end;

class function TSynEdit32HighlighterCS.GetCapabilities: TSynHighlighterCapabilities;
begin
  Result := inherited GetCapabilities + [hcUserSettings];
end;

class function TSynEdit32HighlighterCS.GetFriendlyLanguageName: UnicodeString;
begin
  Result := SYNS_FriendlyLangCS;
end;

initialization
  RegisterPlaceableHighlighter(TSynEdit32HighlighterCS);
end.
