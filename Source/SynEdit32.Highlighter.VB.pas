{-------------------------------------------------------------------------------
The contents of this file are subject to the Mozilla Public License
Version 1.1 (the "License"); you may not use this file except in compliance
with the License. You may obtain a copy of the License at
http://www.mozilla.org/MPL/

Software distributed under the License is distributed on an "AS IS" basis,
WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License for
the specific language governing rights and limitations under the License.

The Original Code is: SynHighlighterVB.pas, released 2000-04-20.
The Original Code is based on the wbADSP21xxSyn.pas file from the
mwEdit component suite by Martin Waldenburg and other developers, the Initial
Author of this file is Max Horv�th.
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

$Id: SynHighlighterVB.pas,v 1.14.2.7 2008/09/14 16:25:03 maelh Exp $

You may retrieve the latest version of this file at the SynEdit home page,
located at http://SynEdit.SourceForge.net

Known Issues:
-------------------------------------------------------------------------------}
{
@abstract(Provides a Visual Basic highlighter for SynEdit)
@author(Max Horv�th <TheProfessor@gmx.de>, converted to SynEdit by David Muir <david@loanhead45.freeserve.co.uk>)
@created(5 December 1999, converted to SynEdit April 21, 2000)
@lastmod(2000-06-23)
The SynHighlighterVB unit provides SynEdit with a Visual Basic (.bas) highlighter.
}

unit SynEdit32.Highlighter.VB;

{$I SynEdit32.Inc}

interface

uses
  Windows, Messages, Controls, Graphics, Registry, SysUtils, Classes,
  SynEdit32.Highlighter, SynEdit32.Types, SynEdit32.Unicode;

type
  TtkTokenKind = (tkComment, tkIdentifier, tkKey, tkNull, tkNumber, tkSpace,
    tkString, tkSymbol, tkUnknown);

  PIdentFuncTableFunc = ^TIdentFuncTableFunc;
  TIdentFuncTableFunc = function (Index: Integer): TtkTokenKind of object;

type
  TSynEdit32HighlighterVB = class(TSynEdit32CustomHighlighter)
  private
    FTokenId: TtkTokenKind;
    FIdentFuncTable: array[0..1422] of TIdentFuncTableFunc;
    FCommentAttri: TSynEdit32HighlighterAttributes;
    FIdentifierAttri: TSynEdit32HighlighterAttributes;
    FKeyAttri: TSynEdit32HighlighterAttributes;
    FNumberAttri: TSynEdit32HighlighterAttributes;
    FSpaceAttri: TSynEdit32HighlighterAttributes;
    FStringAttri: TSynEdit32HighlighterAttributes;
    FSymbolAttri: TSynEdit32HighlighterAttributes;
    function AltFunc(Index: Integer): TtkTokenKind;
    function KeyWordFunc(Index: Integer): TtkTokenKind;
    function FuncRem(Index: Integer): TtkTokenKind;
    function HashKey(Str: PWideChar): Cardinal;
    function IdentKind(MayBe: PWideChar): TtkTokenKind;
    procedure InitIdent;
    procedure SymbolProc;
    procedure ApostropheProc;
    procedure CRProc;
    procedure DateProc;
    procedure GreaterProc;
    procedure IdentProc;
    procedure LFProc;
    procedure LowerProc;
    procedure NullProc;
    procedure NumberProc;
    procedure SpaceProc;
    procedure StringProc;
    procedure UnknownProc;
  protected
    function GetSampleSource: UnicodeString; override;
    function IsFilterStored: Boolean; override;
  public
    class function GetLanguageName: string; override;
    class function GetFriendlyLanguageName: UnicodeString; override;
  public
    constructor Create(AOwner: TComponent); override;
    function GetDefaultAttribute(Index: integer): TSynEdit32HighlighterAttributes;
      override;
    function GetTokenID: TtkTokenKind;
    function GetTokenAttribute: TSynEdit32HighlighterAttributes; override;
    function GetTokenKind: integer; override;
    procedure Next; override;
  published
    property CommentAttri: TSynEdit32HighlighterAttributes read FCommentAttri
      write FCommentAttri;
    property IdentifierAttri: TSynEdit32HighlighterAttributes read FIdentifierAttri
      write FIdentifierAttri;
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
  SynEdit32.StrConst;

const
  KeyWords: array[0..213] of UnicodeString = (
    'abs', 'and', 'appactivate', 'array', 'as', 'asc', 'atn', 'attribute', 
    'base', 'beep', 'begin', 'boolean', 'byte', 'call', 'case', 'cbool', 
    'cbyte', 'ccur', 'cdate', 'cdbl', 'chdir', 'chdrive', 'chr', 'cint', 
    'circle', 'class', 'clear', 'clng', 'close', 'command', 'compare', 'const', 
    'cos', 'createobject', 'csng', 'cstr', 'curdir', 'currency', 'cvar', 
    'cverr', 'date', 'dateadd', 'datediff', 'datepart', 'dateserial', 
    'datevalue', 'ddb', 'deftype', 'dim', 'dir', 'do', 'doevents', 'double', 
    'each', 'else', 'elseif', 'empty', 'end', 'environ', 'eof', 'eqv', 'erase', 
    'err', 'error', 'exit', 'exp', 'explicit', 'fileattr', 'filecopy', 
    'filedatetime', 'filelen', 'fix', 'for', 'form', 'format', 'freefile', 
    'function', 'fv', 'get', 'getattr', 'getobject', 'gosub', 'goto', 'hex', 
    'hour', 'if', 'iif', 'imp', 'input', 'instr', 'int', 'integer', 'ipmt', 
    'irr', 'is', 'isarray', 'isdate', 'isempty', 'iserror', 'ismissing', 
    'isnull', 'isnumeric', 'isobject', 'kill', 'lbound', 'lcase', 'left', 'len', 
    'let', 'line', 'loc', 'lock', 'lof', 'log', 'long', 'loop', 'lset', 'ltrim', 
    'me', 'mid', 'minute', 'mirr', 'mkdir', 'mod', 'module', 'month', 'msgbox', 
    'name', 'new', 'next', 'not', 'nothing', 'now', 'nper', 'npv', 'object', 
    'oct', 'on', 'open', 'option', 'or', 'pmt', 'ppmt', 'print', 'private', 
    'property', 'pset', 'public', 'put', 'pv', 'qbcolor', 'raise', 'randomize', 
    'rate', 'redim', 'rem', 'reset', 'resume', 'return', 'rgb', 'right', 
    'rmdir', 'rnd', 'rset', 'rtrim', 'second', 'seek', 'select', 'sendkeys', 
    'set', 'setattr', 'sgn', 'shell', 'sin', 'single', 'sln', 'space', 'spc', 
    'sqr', 'static', 'stop', 'str', 'strcomp', 'strconv', 'string', 'sub', 
    'switch', 'syd', 'system', 'tab', 'tan', 'then', 'time', 'timer', 
    'timeserial', 'timevalue', 'to', 'trim', 'typename', 'ubound', 'ucase', 
    'unlock', 'until', 'val', 'variant', 'vartype', 'version', 'weekday', 
    'wend', 'while', 'width', 'with', 'write', 'xor' 
  );

  KeyIndices: array[0..1422] of Integer = (
    -1, 117, 59, -1, 10, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, 152, -1, -1, 
    -1, 22, -1, -1, -1, -1, 111, -1, -1, -1, -1, -1, -1, -1, -1, 115, 19, -1, 
    -1, -1, 160, -1, -1, -1, -1, -1, -1, -1, -1, 14, -1, -1, 34, -1, 54, -1, -1, 
    31, 161, -1, 87, -1, 173, -1, -1, -1, -1, 76, -1, -1, -1, 138, -1, -1, -1, 
    -1, -1, 176, -1, 177, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, 193, -1, 
    178, -1, -1, -1, -1, -1, -1, 72, -1, -1, -1, -1, -1, -1, 131, -1, -1, -1, 
    -1, -1, -1, 188, -1, -1, -1, -1, -1, -1, -1, 194, 209, -1, -1, -1, 88, -1, 
    120, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, 170, -1, -1, -1, -1, 185, -1, 
    -1, -1, -1, 198, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, 
    -1, -1, -1, -1, -1, 73, -1, 157, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, 
    67, -1, -1, -1, 130, -1, 82, -1, -1, 99, -1, -1, -1, -1, -1, -1, -1, -1, -1, 
    -1, -1, -1, 186, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, 168, -1, -1, -1, 
    206, 40, -1, -1, 143, 202, -1, -1, -1, -1, -1, 158, -1, -1, -1, -1, -1, -1, 
    -1, -1, -1, -1, -1, -1, 114, -1, -1, -1, 89, -1, -1, -1, -1, -1, -1, -1, -1, 
    -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, 174, -1, 146, 
    -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, 
    -1, -1, -1, -1, 97, 69, -1, 29, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, 
    -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, 127, -1, -1, -1, -1, 184, -1, -1, 
    -1, 153, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, 
    -1, 199, 48, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, 
    -1, 112, 90, -1, -1, -1, -1, -1, -1, 179, -1, -1, -1, -1, -1, -1, -1, 119, 
    -1, -1, -1, 25, -1, -1, -1, -1, -1, 74, -1, -1, -1, -1, -1, -1, -1, -1, -1, 
    -1, -1, -1, 125, -1, -1, -1, -1, -1, -1, -1, 126, -1, -1, -1, 65, -1, -1, 
    -1, 134, -1, -1, 8, -1, -1, -1, -1, -1, -1, -1, 155, -1, -1, -1, -1, -1, -1, 
    -1, -1, -1, 150, -1, -1, -1, -1, -1, -1, -1, 86, -1, 147, 148, -1, -1, -1, 
    -1, -1, 107, 164, 203, -1, 102, -1, -1, -1, -1, -1, -1, -1, -1, 103, -1, -1, 
    -1, -1, -1, 68, -1, -1, 101, 32, 201, -1, -1, -1, -1, -1, -1, 95, -1, -1, 
    124, 0, -1, -1, -1, -1, -1, -1, -1, -1, -1, 79, -1, -1, -1, -1, -1, -1, -1, 
    -1, -1, 172, -1, 23, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, 
    -1, -1, -1, -1, -1, -1, 207, -1, -1, -1, -1, -1, -1, -1, 175, -1, 129, -1, 
    -1, -1, -1, -1, -1, -1, 30, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, 
    -1, 58, -1, -1, 141, -1, -1, -1, 181, -1, -1, -1, 166, 80, -1, -1, -1, -1, 
    -1, -1, -1, -1, -1, -1, -1, 197, -1, -1, 133, 28, -1, -1, -1, 21, -1, -1, 
    -1, -1, -1, -1, -1, -1, -1, 66, -1, -1, -1, -1, -1, -1, -1, -1, 36, -1, -1, 
    -1, -1, -1, -1, 104, -1, 12, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, 
    92, -1, -1, 180, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, 
    -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, 
    -1, -1, -1, -1, 108, -1, 151, -1, -1, -1, -1, -1, -1, -1, -1, -1, 9, -1, 
    156, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, 205, -1, -1, -1, -1, -1, 
    -1, -1, -1, 136, 55, -1, -1, -1, -1, 35, -1, -1, -1, -1, -1, -1, -1, -1, -1, 
    53, -1, -1, -1, -1, -1, -1, -1, -1, 100, -1, -1, -1, 51, 70, -1, -1, -1, -1, 
    204, -1, -1, -1, -1, -1, -1, 24, -1, -1, 71, -1, -1, -1, -1, -1, 45, -1, -1, 
    -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, 210, -1, 94, 84, 
    -1, -1, 189, -1, -1, -1, -1, -1, 128, -1, -1, -1, -1, -1, -1, -1, -1, -1, 
    -1, -1, -1, 122, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, 83, -1, 
    -1, -1, -1, -1, -1, -1, 38, -1, 213, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, 
    -1, -1, 162, -1, -1, -1, -1, -1, -1, -1, -1, -1, 17, -1, -1, -1, 47, 18, 
    187, -1, -1, 137, 105, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, 
    -1, -1, -1, -1, -1, -1, -1, -1, -1, 42, -1, -1, -1, -1, -1, -1, -1, -1, -1, 
    -1, -1, -1, -1, 182, -1, 4, 75, -1, -1, -1, -1, -1, -1, 118, -1, -1, -1, -1, 
    -1, 20, 60, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, 62, -1, -1, -1, 
    -1, -1, -1, 93, 98, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, 81, -1, -1, -1, 
    -1, -1, -1, -1, -1, 110, -1, -1, -1, -1, -1, -1, -1, -1, -1, 167, -1, -1, 
    -1, 26, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, 
    -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, 132, -1, -1, 196, -1, -1, -1, 85, 
    -1, -1, -1, -1, 140, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, 78, 11, -1, 
    -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, 200, -1, -1, 
    169, -1, -1, -1, -1, 159, -1, -1, 56, -1, -1, -1, -1, -1, -1, -1, -1, -1, 
    -1, -1, -1, -1, -1, -1, 211, -1, -1, -1, -1, -1, -1, 2, -1, -1, -1, -1, -1, 
    -1, -1, -1, -1, 44, -1, -1, -1, -1, 61, 15, -1, 27, -1, -1, -1, -1, 6, -1, 
    -1, -1, -1, -1, -1, -1, -1, 113, 39, -1, -1, -1, -1, -1, 91, -1, -1, 77, -1, 
    -1, -1, -1, -1, -1, -1, -1, -1, -1, 64, -1, -1, -1, -1, -1, -1, -1, -1, -1, 
    -1, -1, -1, -1, -1, -1, -1, 171, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, 
    145, -1, 195, 52, -1, -1, -1, -1, -1, -1, -1, -1, 1, -1, -1, -1, -1, -1, -1, 
    57, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, 
    -1, 7, -1, -1, 33, -1, -1, -1, -1, -1, -1, 142, -1, -1, -1, -1, -1, 96, -1, 
    106, -1, 139, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, 
    -1, -1, 212, 5, -1, 190, -1, -1, 49, 50, -1, -1, -1, -1, -1, -1, 46, 3, -1, 
    109, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, 165, -1, -1, 
    -1, 16, -1, -1, -1, -1, -1, 144, -1, 192, -1, -1, -1, -1, -1, -1, -1, -1, 
    -1, 183, -1, -1, -1, 13, 135, -1, -1, -1, -1, 121, -1, -1, -1, -1, -1, -1, 
    -1, -1, -1, -1, -1, -1, -1, 63, -1, -1, -1, 163, -1, -1, -1, -1, -1, -1, -1, 
    41, 149, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, 
    -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, 123, -1, -1, -1, 208, -1, -1, -1, 
    -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, 191, -1, -1, 
    43, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, 116, -1, -1, -1, 
    37, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, 154, -1 
  );

{$Q-}
function TSynEdit32HighlighterVB.HashKey(Str: PWideChar): Cardinal;
begin
  Result := 0;
  while IsIdentChar(Str^) do
  begin
    Result := Result * 251 + Ord(Str^) * 749;
    Inc(Str);
  end;
  Result := Result mod 1423;
  FStringLen := Str - FToIdent;
end;
{$Q+}

function TSynEdit32HighlighterVB.IdentKind(MayBe: PWideChar): TtkTokenKind;
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

procedure TSynEdit32HighlighterVB.InitIdent;
var
  i: Integer;
begin
  for i := Low(FIdentFuncTable) to High(FIdentFuncTable) do
    if KeyIndices[i] = -1 then
      FIdentFuncTable[i] := AltFunc;

  FIdentFuncTable[436] := FuncRem;

  for i := Low(FIdentFuncTable) to High(FIdentFuncTable) do
    if @FIdentFuncTable[i] = nil then
      FIdentFuncTable[i] := KeyWordFunc;
end;

function TSynEdit32HighlighterVB.AltFunc(Index: Integer): TtkTokenKind;
begin
  Result := tkIdentifier;
end;

function TSynEdit32HighlighterVB.KeyWordFunc(Index: Integer): TtkTokenKind;
begin
  if IsCurrentToken(KeyWords[Index]) then
    Result := tkKey
  else
    Result := tkIdentifier
end;

function TSynEdit32HighlighterVB.FuncRem(Index: Integer): TtkTokenKind;
begin
  if IsCurrentToken(KeyWords[Index]) then
  begin
    ApostropheProc;
    FStringLen := 0;
    Result := tkComment;
  end
  else
    Result := tkIdentifier;
end;

constructor TSynEdit32HighlighterVB.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

  FCaseSensitive := False;

  FCommentAttri := TSynEdit32HighlighterAttributes.Create(SYNS_AttrComment, SYNS_FriendlyAttrComment);
  FCommentAttri.Style:= [fsItalic];
  AddAttribute(FCommentAttri);
  FIdentifierAttri := TSynEdit32HighlighterAttributes.Create(SYNS_AttrIdentifier, SYNS_FriendlyAttrIdentifier);
  AddAttribute(FIdentifierAttri);
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
  SetAttributesOnChange(DefHighlightChange);
  InitIdent;
  FDefaultFilter := SYNS_FilterVisualBASIC;
end;

procedure TSynEdit32HighlighterVB.SymbolProc;
begin
  Inc(FRun);
  FTokenId := tkSymbol;
end;

procedure TSynEdit32HighlighterVB.ApostropheProc;
begin
  FTokenId := tkComment;
  repeat
    Inc(FRun);
  until IsLineEnd(FRun);
end;

procedure TSynEdit32HighlighterVB.CRProc;
begin
  FTokenId := tkSpace;
  Inc(FRun);
  if FLine[FRun] = #10 then Inc(FRun);
end;

procedure TSynEdit32HighlighterVB.DateProc;
begin
  FTokenId := tkString;
  repeat
    if IsLineEnd(FRun) then break;
    Inc(FRun);
  until FLine[FRun] = '#';
  if not IsLineEnd(FRun) then Inc(FRun);
end;

procedure TSynEdit32HighlighterVB.GreaterProc;
begin
  FTokenId := tkSymbol;
  Inc(FRun);
  if FLine[FRun] = '=' then Inc(FRun);
end;

procedure TSynEdit32HighlighterVB.IdentProc;
begin
  FTokenId := IdentKind(FLine + FRun);
  Inc(FRun, FStringLen);
  while IsIdentChar(FLine[FRun]) do Inc(FRun);
end;

procedure TSynEdit32HighlighterVB.LFProc;
begin
  FTokenId := tkSpace;
  Inc(FRun);
end;

procedure TSynEdit32HighlighterVB.LowerProc;
begin
  FTokenId := tkSymbol;
  Inc(FRun);
  if CharInSet(FLine[FRun], ['=', '>']) then Inc(FRun);
end;

procedure TSynEdit32HighlighterVB.NullProc;
begin
  FTokenId := tkNull;
  Inc(FRun);
end;

procedure TSynEdit32HighlighterVB.NumberProc;

  function IsNumberChar: Boolean;
  begin
    case FLine[FRun] of
      '0'..'9', '.', 'e', 'E':
        Result := True;
      else
        Result := False;
    end;
  end;

begin
  Inc(FRun);
  FTokenId := tkNumber;
  while IsNumberChar do Inc(FRun);
end;

procedure TSynEdit32HighlighterVB.SpaceProc;
begin
  Inc(FRun);
  FTokenId := tkSpace;
  while (FLine[FRun] <= #32) and not IsLineEnd(FRun) do Inc(FRun);
end;

procedure TSynEdit32HighlighterVB.StringProc;
begin
  FTokenId := tkString;
  if (FLine[FRun + 1] = #34) and (FLine[FRun + 2] = #34) then Inc(FRun, 2);
  repeat
    if IsLineEnd(FRun) then break;
    Inc(FRun);
  until FLine[FRun] = #34;
  if not IsLineEnd(FRun) then Inc(FRun);
end;

procedure TSynEdit32HighlighterVB.UnknownProc;
begin
  Inc(FRun);
  FTokenId := tkUnknown;
end;

procedure TSynEdit32HighlighterVB.Next;
begin
  fTokenPos := FRun;
  case FLine[FRun] of
    '&': SymbolProc;
    #39: ApostropheProc;
    '}': SymbolProc;
    '{': SymbolProc;
    #13: CRProc;
    ':': SymbolProc;
    ',': SymbolProc;
    '#': DateProc;
    '=': SymbolProc;
    '^': SymbolProc;
    '>': GreaterProc;
    'A'..'Z', 'a'..'z', '_': IdentProc;
    #10: LFProc;
    '<': LowerProc;
    '-': SymbolProc;
    #0: NullProc;
    '0'..'9': NumberProc;
    '+': SymbolProc;
    '.': SymbolProc;
    ')': SymbolProc;
    '(': SymbolProc;
    ';': SymbolProc;
    '/': SymbolProc;
    #1..#9, #11, #12, #14..#32: SpaceProc;
    '*': SymbolProc;
    #34: StringProc;
    else UnknownProc;
  end;
  inherited;
end;

function TSynEdit32HighlighterVB.GetDefaultAttribute(Index: integer):
  TSynEdit32HighlighterAttributes;
begin
  case Index of
    SYN_ATTR_COMMENT: Result := FCommentAttri;
    SYN_ATTR_IDENTIFIER: Result := FIdentifierAttri;
    SYN_ATTR_KEYWORD: Result := FKeyAttri;
    SYN_ATTR_STRING: Result := FStringAttri;
    SYN_ATTR_WHITESPACE: Result := FSpaceAttri;
    SYN_ATTR_SYMBOL: Result := FSymbolAttri;
  else
    Result := nil;
  end;
end;

function TSynEdit32HighlighterVB.GetTokenID: TtkTokenKind;
begin
  Result := FTokenId;
end;

function TSynEdit32HighlighterVB.GetTokenAttribute: TSynEdit32HighlighterAttributes;
begin
  case GetTokenID of
    tkComment: Result := FCommentAttri;
    tkIdentifier: Result := FIdentifierAttri;
    tkKey: Result := FKeyAttri;
    tkNumber: Result := FNumberAttri;
    tkSpace: Result := FSpaceAttri;
    tkString: Result := FStringAttri;
    tkSymbol: Result := FSymbolAttri;
    tkUnknown: Result := FIdentifierAttri;
    else Result := nil;
  end;
end;

function TSynEdit32HighlighterVB.GetTokenKind: integer;
begin
  Result := Ord(FTokenId);
end;

function TSynEdit32HighlighterVB.IsFilterStored: Boolean;
begin
  Result := FDefaultFilter <> SYNS_FilterVisualBASIC;
end;

class function TSynEdit32HighlighterVB.GetLanguageName: string;
begin
  Result := SYNS_LangVisualBASIC;
end;

function TSynEdit32HighlighterVB.GetSampleSource: UnicodeString;
begin
  Result := ''' Syntax highlighting'#13#10+
            'Function PrintNumber'#13#10+
            '  Dim Number'#13#10+
            '  Dim X'#13#10+
            ''#13#10+
            '  Number = 123456'#13#10+
            '  Response.Write "The number is " & number'#13#10+
            ''#13#10+
            '  For I = 0 To Number'#13#10+
            '    X = X + &h4c'#13#10+
            '    X = X - &o8'#13#10+
            '    X = X + 1.0'#13#10+
            '  Next'#13#10+
            ''#13#10+
            '  I = I + @;  '' illegal character'#13#10+
            'End Function';
end;

class function TSynEdit32HighlighterVB.GetFriendlyLanguageName: UnicodeString;
begin
  Result := SYNS_FriendlyLangVisualBASIC;
end;

initialization
  RegisterPlaceableHighlighter(TSynEdit32HighlighterVB);
end.
