{-------------------------------------------------------------------------------
The contents of this file are subject to the Mozilla Public License
Version 1.1 (the "License"); you may not use this file except in compliance
with the License. You may obtain a copy of the License at
http://www.mozilla.org/MPL/

Software distributed under the License is distributed on an "AS IS" basis,
WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License for
the specific language governing rights and limitations under the License.

The Original Code is: SynHighlighterMulti.pas, released 2000-06-23.
The Original Code is based on mwMultiSyn.pas by Willo van der Merwe, part of the
mwEdit component suite.
Unicode translation by Ma�l H�rz.

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

$Id: SynHighlighterMulti.pas,v 1.34.2.11 2008/09/14 16:25:00 maelh Exp $

You may retrieve the latest version of this file at the SynEdit home page,
located at http://SynEdit.SourceForge.net

Known Issues:
-------------------------------------------------------------------------------}
{
@abstract(Provides a Multiple-highlighter syntax highlighter for SynEdit)
@author(Willo van der Merwe <willo@wack.co.za>, converted to SynEdit by David Muir <dhm@dmsoftware.co.uk>)
@created(1999, converted to SynEdit 2000-06-23)
@lastmod(2000-06-23)
The SynHighlighterMulti unit provides SynEdit with a multiple-highlighter syntax highlighter.
This highlighter can be used to highlight text in which several languages are present, such as HTML.
For example, in HTML as well as HTML tags there can also be JavaScript and/or VBScript present.
}

unit SynEdit32.Highlighter.Multi;

{$I SynEdit32.inc}

interface

uses
  Windows,
  Classes,
  SynEdit32.Types,
  SynEdit32.Highlighter,
  SynEdit32.Unicode;

type
  TOnCheckMarker = procedure (Sender: TObject; var StartPos, MarkerLen: Integer;
    var MarkerText: UnicodeString; Line: Integer; const LineStr: string) of object;

  TScheme = class(TCollectionItem)
  private
    FEndExpr: UnicodeString;
    FStartExpr: UnicodeString;
    FHighlighter: TSynEdit32CustomHighLighter;
    FMarkerAttri: TSynEdit32HighlighterAttributes;
    FSchemeName: TComponentName;
    FCaseSensitive: Boolean;
    FOnCheckStartMarker: TOnCheckMarker;
    FOnCheckEndMarker: TOnCheckMarker;
    function ConvertExpression(const Value: UnicodeString): UnicodeString;
    procedure MarkerAttriChanged(Sender: TObject);
    procedure SetMarkerAttri(const Value: TSynEdit32HighlighterAttributes);
    procedure SetHighlighter(const Value: TSynEdit32CustomHighLighter);
    procedure SetEndExpr(const Value: UnicodeString);
    procedure SetStartExpr(const Value: UnicodeString);
    procedure SetCaseSensitive(const Value: Boolean);
  protected
    function GetDisplayName: string; override;
    procedure SetDisplayName(const Value: string); override;
  public
    constructor Create(Collection: TCollection); override;
    destructor Destroy; override;
  published
    property CaseSensitive: Boolean read FCaseSensitive write SetCaseSensitive
      default True;
    property StartExpr: UnicodeString read FStartExpr write SetStartExpr;
    property EndExpr: UnicodeString read FEndExpr write SetEndExpr;
    property Highlighter: TSynEdit32CustomHighLighter read FHighlighter
      write SetHighlighter;
    property MarkerAttri: TSynEdit32HighlighterAttributes read FMarkerAttri
      write SetMarkerAttri;
    property SchemeName: TComponentName read FSchemeName write FSchemeName;
    property OnCheckStartMarker: TOnCheckMarker read FOnCheckStartMarker write FOnCheckStartMarker;
    property OnCheckEndMarker: TOnCheckMarker read FOnCheckEndMarker write FOnCheckEndMarker;
  end;

  TgmSchemeClass = class of TScheme;

  TSynEdit32HighlighterMulti = class;

  TSchemes = class(TCollection)
  private
    FOwner: TSynEdit32HighlighterMulti;
    function GetItems(Index: integer): TScheme;
    procedure SetItems(Index: integer; const Value: TScheme);
  protected
    function GetOwner: TPersistent; override;
    procedure Update(Item: TCollectionItem); override;
  public
    constructor Create(aOwner: TSynEdit32HighlighterMulti);
    property Items[aIndex: integer]: TScheme read GetItems write SetItems;
      default;
  end;

  TMarker = class
  protected
    FScheme: Integer;
    FStartPos: Integer;
    FMarkerLen: Integer;
    FMarkerText: UnicodeString;
    FIsOpenMarker: Boolean;
  public
    constructor Create(aScheme, aStartPos, aMarkerLen: Integer;
      aIsOpenMarker: Boolean; const aMarkerText: UnicodeString);
  end;


  TRangeOperation = (roGet, roSet);

  TRangeUNativeInt = NativeUInt;
  TRangeProc = procedure (Operation: TRangeOperation; var Range: TRangeUNativeInt) of object;

  TCustomRangeEvent = procedure (Sender: TSynEdit32HighlighterMulti; Operation: TRangeOperation;
    var Range: pointer) of object;

  {
  * Usage notes *
    If you don't need to nest MultiSyns as Schemes, just as DefaultHighlighter,
  you can nest up to 2 MultiSyns, each of them containing up to 7 Schemes. This
  is the way MultiSyn works best. (implemented in NewRangeProc)
    If you need to use a MultiSyn nested as Scheme, then you can nest up to
  5 MultiSyns, but Ranges aren't persisted across occurrences of Schemes that
  have multiple lines. (implemented in OldRangeProc)
    Clarification: when I say "you can nest up to X" MultiSyns, I mean having
  X+1 levels of MultiSyns.

  MultiSyn doesn't work by default with dynamic highlighters; you must use
  OnCustomRange. This is because dynamic highlighters' Ranges are pointers,
  but MultiSyn needs Ranges to be ordinal values smaller than 16 (4 bits).

  OnCustomRange:
    When Operation is roGet, user should store in the 'Range' parameter the
    information to allow restoring the current state of the highlighter.
    When Operation is roSet, user should restore highlighter state (CurrScheme,
    DefaultHighlighter.Range and, if the case, Schemes[CurrScheme].Range)
    according to 'Range' value.
  CurrScheme:
    Index of the scheme that is currently parsing. DefaultHighlighter maps to -1.

  * Implementation notes *
  FTmpRange:
    Using the OldRangeProc, FTmpRange was the only way to restore the Range
    of the DefaultHighlighter after a Scheme spanned across multiple lines.
    With the NewRangeProc, the only use for it is restoring DefaultHighLighter's
    Range in case a nested MultiSyn uses the highlighter too.
  }

  TSynEdit32HighlighterMulti = class(TSynEdit32CustomHighLighter)
  private
    FRangeProc: TRangeProc;
    FDefaultLanguageName: string;
    FMarkers: TList;
    FMarker: TMarker;
    FNextMarker: integer;
    FCurrScheme: integer;
    FTmpRange: pointer;
    FOnCustomRange: TCustomRangeEvent;
    FLineStr: UnicodeString;
    procedure SetDefaultHighlighter(const Value: TSynEdit32CustomHighLighter);
    function GetMarkers(Index: Integer): TMarker;
    property Markers[Index: Integer]: TMarker read GetMarkers;
    procedure DoCheckMarker(Scheme:TScheme; StartPos, MarkerLen: Integer;
      const MarkerText: UnicodeString; Start: Boolean; Line: Integer;
      const LineStr: string);
    procedure SetOnCustomRange(const Value: TCustomRangeEvent);
  protected
    FSchemes: TSchemes;
    FDefaultHighlighter: TSynEdit32CustomHighLighter;
    FLineNumber: Integer;
    FSampleSource: UnicodeString;
    procedure Loaded; override;
    procedure SetSchemes(const Value: TSchemes);
    procedure ClearMarkers;
    function GetDefaultAttribute(Index: integer): TSynEdit32HighlighterAttributes; override;
    function GetAttribCount: integer; override;
    function GetAttribute(Index: integer): TSynEdit32HighlighterAttributes; override;
    procedure HookHighlighter(aHL: TSynEdit32CustomHighLighter);
    procedure UnhookHighlighter(aHL: TSynEdit32CustomHighLighter);
    procedure Notification(aComp: TComponent; aOp: TOperation); override;
    function GetSampleSource: UnicodeString; override;
    procedure SetSampleSource(Value: UnicodeString); override;
    procedure DoSetLine(const Value: UnicodeString; LineNumber: Integer); override;
    //
    procedure OldRangeProc(Operation: TRangeOperation; var Range: TRangeUNativeInt);
    procedure NewRangeProc(Operation: TRangeOperation; var Range: TRangeUNativeInt);
    procedure UserRangeProc(Operation: TRangeOperation; var Range: TRangeUNativeInt);
  public
    class function GetLanguageName: string; override;
    class function GetFriendlyLanguageName: UnicodeString; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    function GetEol: Boolean; override;
    function GetExpandedToken: UnicodeString; override;
    function GetRange: Pointer; override;
    function GetToken: UnicodeString; override;
    function GetTokenAttribute: TSynEdit32HighlighterAttributes; override;
    function GetTokenKind: integer; override;
    procedure Next; override;
    procedure SetRange(Value: Pointer); override;
    procedure ResetRange; override;
    function UpdateRangeProcs: Boolean;
    property CurrScheme: Integer read FCurrScheme write FCurrScheme;
    property CurrLine: UnicodeString read FLineStr;
    function LoadFromRegistry(RootKey: HKEY; Key: string): Boolean; override;
    function SaveToRegistry(RootKey: HKEY; Key: string): Boolean; override;
    function IsIdentChar(AChar: WideChar): Boolean; override;
  published
    property Schemes: TSchemes read FSchemes write SetSchemes;
    property DefaultHighlighter: TSynEdit32CustomHighLighter read FDefaultHighlighter
      write SetDefaultHighlighter;
    property DefaultLanguageName: string read FDefaultLanguageName
      write FDefaultLanguageName;
    property OnCustomRange: TCustomRangeEvent read FOnCustomRange write SetOnCustomRange;
  end;

implementation

uses
  Graphics,
  Registry,
  SysUtils,
  SynEdit32.MiscProcs,
  SynEdit32.RegExpr,
  SynEdit32.StrConst;

procedure CheckExpression(const Expr: UnicodeString);
var
  Parser: TRegExpr;
begin
  Parser := TRegExpr.Create;
  try
    Parser.Expression := Expr;
    try
      Parser.Compile;
    except
      on E: ERegExpr do
      begin
        if E.ErrorCode < 1000 then
          E.Message := Format('"%s" is not a valid Regular Expression.'#13'Error (pos %d): %s',
            [Expr, E.CompilerErrorPos, Copy(Parser.ErrorMsg(E.ErrorCode), 16, MaxInt)]);
        raise;
      end;
    end;
  finally
    Parser.Free;
  end;
end;

{ TMarker }

constructor TMarker.Create(aScheme, aStartPos,
  aMarkerLen: Integer; aIsOpenMarker: Boolean; const aMarkerText: UnicodeString);
begin
  FScheme := aScheme;
  FStartPos := aStartPos;
  FMarkerLen := aMarkerLen;
  FIsOpenMarker := aIsOpenMarker;
  FMarkerText := aMarkerText;
end;

{ TSynEdit32HighlighterMulti }

procedure TSynEdit32HighlighterMulti.ClearMarkers;
var
  i: Integer;
begin
  for i := 0 to FMarkers.Count - 1 do
    TObject(FMarkers[i]).Free;
  FMarkers.Clear;
end;

constructor TSynEdit32HighlighterMulti.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FSchemes := TSchemes.Create(Self);
  FCurrScheme := -1;
  FMarkers := TList.Create;
  FRangeProc := NewRangeProc;
end;

destructor TSynEdit32HighlighterMulti.Destroy;
begin
  ClearMarkers;
  { unhook notification handlers }
  Schemes.Clear;
  DefaultHighlighter := nil;
  inherited Destroy;
  FSchemes.Free;
  FMarkers.Free;
end;

function TSynEdit32HighlighterMulti.GetAttribCount: Integer;
var
  i: Integer;
begin
  Result := Schemes.Count;
  if DefaultHighlighter <> nil then
    Inc(Result, DefaultHighlighter.AttrCount);
  for i := 0 to Schemes.Count - 1 do
    if Schemes[i].Highlighter <> nil then
      Inc(Result, Schemes[i].Highlighter.AttrCount);
end;

function TSynEdit32HighlighterMulti.GetAttribute(Index: Integer): TSynEdit32HighlighterAttributes;
var
  i: Integer;
  HL: TSynEdit32CustomHighLighter;
begin
  if Index < Schemes.Count then
    Result := Schemes[Index].MarkerAttri
  else
  begin
    Dec(Index, Schemes.Count);
    if DefaultHighlighter <> nil then
      if Index < DefaultHighlighter.AttrCount then
      begin
        Result := DefaultHighlighter.Attribute[Index];
        Exit;
      end
      else
        Dec(Index, DefaultHighlighter.AttrCount);
    for i := 0 to Schemes.Count - 1 do
    begin
      HL := Schemes[i].Highlighter;
      if HL <> nil then
        if Index < HL.AttrCount then
        begin
          Result := HL.Attribute[Index];
          Exit;
        end
        else
          Dec(Index, HL.AttrCount);
    end;
    Result := nil;
  end;
end;

function TSynEdit32HighlighterMulti.GetDefaultAttribute(Index: integer): TSynEdit32HighlighterAttributes;
var
  HL: TSynEdit32CustomHighLighter;
begin
  if (CurrScheme >= 0) and (Schemes[CurrScheme].Highlighter <> nil) then
    HL := Schemes[CurrScheme].Highlighter
  else
    HL := DefaultHighlighter;
  { the typecast to TSynEdit32HighlighterMulti is only necessary because the
  GetDefaultAttribute method is protected.
  And don't worry: this really works }
  if HL <> nil then
    Result := TSynEdit32HighlighterMulti(HL).GetDefaultAttribute(Index)
  else
    Result := nil;
end;

function TSynEdit32HighlighterMulti.GetEol: Boolean;
begin
  if FMarker <> nil then
    Result := False
  else if FCurrScheme >= 0 then
    Result := Schemes[CurrScheme].Highlighter.GetEol
  else if DefaultHighlighter <> nil then
    Result := DefaultHighlighter.GetEol
  else
    Result := FRun > fLineLen + 1;
end;

class function TSynEdit32HighlighterMulti.GetLanguageName: string;
begin
  Result := SYNS_LangGeneralMulti;
end;

function TSynEdit32HighlighterMulti.GetMarkers(Index: integer): TMarker;
begin
  Result := TMarker(FMarkers[Index]);
end;

procedure TSynEdit32HighlighterMulti.OldRangeProc(Operation: TRangeOperation; var Range: TRangeUNativeInt);
const
  MaxNestedMultiSyn = 6;
  { number of bits of the Range that will be used to store the SchemeIndex }
  SchemeIndexSize = 4;
  MaxSchemeCount = (1 shl SchemeIndexSize) - 1;
  { number of bits of the Range that will be used to store the SchemeRange }
  SchemeRangeSize = 8;
  MaxSchemeRange = (1 shl SchemeRangeSize) - 1;
var
  iHL: TSynEdit32CustomHighLighter;
  iSchemeIndex: cardinal;
  iSchemeRange: cardinal;
begin
  if Operation = roGet then
  begin
    if (FCurrScheme < 0) then
      iHL := DefaultHighlighter
    else
      iHL := Schemes[FCurrScheme].Highlighter;
    iSchemeIndex := FCurrScheme + 2;
    Assert(iSchemeIndex <= MaxSchemeCount);
    if iHL <> nil then
    begin
      iSchemeRange := cardinal(iHL.GetRange);
      Assert((iSchemeRange <= MaxSchemeRange) or (iHL is TSynEdit32HighlighterMulti));
    end
    else
      iSchemeRange := 0;
    { checks the limit of nested MultiSyns }
    Assert(iSchemeRange shr ((MaxNestedMultiSyn - 1) * SchemeIndexSize + SchemeRangeSize) = 0);
    iSchemeRange := (iSchemeRange shl SchemeIndexSize) or iSchemeIndex;
    Range := iSchemeRange;
  end
  else
  begin
    if Range = 0 then
      Exit;
    iSchemeRange := cardinal(Range);
    FCurrScheme := integer(iSchemeRange and MaxSchemeCount) - 2;
    iSchemeRange := iSchemeRange shr SchemeIndexSize;
    if (CurrScheme < 0) then
    begin
      if DefaultHighlighter <> nil then
        DefaultHighlighter.SetRange(pointer(iSchemeRange));
    end
    else
      Schemes[CurrScheme].Highlighter.SetRange(pointer(iSchemeRange));
  end;
end;

function TSynEdit32HighlighterMulti.GetToken: UnicodeString;
begin
  if DefaultHighlighter = nil then
    Result := FLineStr
  else
    Result := inherited GetToken;
end;

function TSynEdit32HighlighterMulti.GetTokenAttribute: TSynEdit32HighlighterAttributes;
begin
  if FMarker <> nil then
    Result := Schemes[FMarker.FScheme].MarkerAttri
  else if CurrScheme >= 0 then
    Result := Schemes[CurrScheme].Highlighter.GetTokenAttribute
  else if DefaultHighlighter <> nil then
    Result := DefaultHighlighter.GetTokenAttribute
  else
    Result := nil;
end;

function TSynEdit32HighlighterMulti.GetTokenKind: integer;
begin
  if FMarker <> nil then
    Result := 0
  else if FCurrScheme >= 0 then
    Result := Schemes[FCurrScheme].Highlighter.GetTokenKind
  else if DefaultHighlighter <> nil then
    Result := DefaultHighlighter.GetTokenKind
  else
    Result := 0;
end;

procedure TSynEdit32HighlighterMulti.HookHighlighter(aHL: TSynEdit32CustomHighLighter);
begin
  aHL.FreeNotification(Self);
  aHL.HookAttrChangeEvent(DefHighlightChange);
end;

procedure TSynEdit32HighlighterMulti.Next;
var
  iToken, TmpLine, ExpandedTmpLine: UnicodeString;
  iHL: TSynEdit32CustomHighLighter;
begin
  if DefaultHighlighter = nil then
  begin
    if FRun > 0 then
      Inc(FRun)
    else
      FRun := Length(FLineStr) + 1;
    inherited;
    Exit;
  end;

  if (FNextMarker < FMarkers.Count) and (FRun + 1 >= Markers[FNextMarker].FStartPos) then
  begin
    FMarker := Markers[FNextMarker];
    if FMarker.FIsOpenMarker then
    begin
      FCurrScheme := FMarker.FScheme;
      FTmpRange := DefaultHighlighter.GetRange;
      Schemes[CurrScheme].Highlighter.ResetRange;
    end;
    Inc(FNextMarker);
    fTokenPos := FRun;
    Inc(FRun, FMarker.FMarkerLen);
    inherited;
    Exit;
  end;

  if FRun = 0 then
  begin
    if CurrScheme >= 0 then
      iHL := Schemes[CurrScheme].Highlighter
    else
      iHL := DefaultHighlighter;

    if FMarkers.Count = 0 then
      TmpLine := FLineStr
    else
      TmpLine := Copy(FLineStr, 1, Markers[FNextMarker].FStartPos - 1);
      
    if fExpandedLine <> nil then
    begin
      if FMarkers.Count = 0 then
        ExpandedTmpLine := fExpandedLineStr
      else
        ExpandedTmpLine := Copy(fExpandedLineStr, 1,
          PosToExpandedPos(Markers[FNextMarker].FStartPos - 1));
      iHL.SetLineExpandedAtWideGlyphs(TmpLine, ExpandedTmpLine, FLineNumber);
    end
    else
      iHL.SetLine(TmpLine, FLineNumber);
  end
  else if FMarker <> nil then
  begin
    if not FMarker.FIsOpenMarker then
    begin
      FCurrScheme := -1;
      DefaultHighlighter.SetRange(FTmpRange);
    end;
    FMarker := nil;

    if CurrScheme >= 0 then
      iHL := Schemes[CurrScheme].Highlighter
    else
      iHL := DefaultHighlighter;

    if FNextMarker < FMarkers.Count then
      TmpLine := Copy(FLineStr, FRun + 1, Markers[FNextMarker].FStartPos - FRun - 1)
    else
      TmpLine := Copy(FLineStr, FRun + 1, MaxInt);

    if fExpandedLine <> nil then
    begin
      if FNextMarker < FMarkers.Count then
        ExpandedTmpLine := Copy(fExpandedLineStr, FExpandedRun + 1,
          PosToExpandedPos(Markers[FNextMarker].FStartPos - FRun - 1))
      else
        ExpandedTmpLine := Copy(fExpandedLineStr, FExpandedRun + 1, MaxInt);

      iHL.SetLineExpandedAtWideGlyphs(TmpLine, ExpandedTmpLine, FLineNumber);
    end
    else
      iHL.SetLine(TmpLine, FLineNumber);
  end
  else
  begin
    if CurrScheme >= 0 then
      iHL := Schemes[CurrScheme].Highlighter
    else
      iHL := DefaultHighlighter;
    iHL.Next;
  end;

  fTokenPos := iHL.GetTokenPos;
  iToken := iHL.GetToken;
  if FNextMarker > 0 then
    with Markers[FNextMarker - 1] do
      Inc(fTokenPos, FStartPos + FMarkerLen - 1);
  Inc(FRun, (fTokenPos - FRun) + Length(iToken));
  inherited;
end;

procedure TSynEdit32HighlighterMulti.Notification(aComp: TComponent; aOp: TOperation);
var
  i: Integer;
begin
  inherited;
  // 'opRemove' doesn't mean the component is being destroyed. It means it's
  // being removed from its Owner's list of Components.
  if (aOp = opRemove) and (aComp is TSynEdit32CustomHighLighter) and
    (csDestroying in aComp.ComponentState) then
  begin
    if DefaultHighlighter = aComp then
      DefaultHighlighter := nil;
    for i := 0 to Schemes.Count - 1 do
      if Schemes[i].Highlighter = aComp then
        Schemes[i].Highlighter := nil;
  end;
end;

procedure TSynEdit32HighlighterMulti.ResetRange;
begin
  FCurrScheme := -1;
  if DefaultHighlighter <> nil then
  begin
    DefaultHighlighter.ResetRange;
    FTmpRange := DefaultHighlighter.GetRange;
  end;
end;

procedure TSynEdit32HighlighterMulti.SetDefaultHighlighter(
  const Value: TSynEdit32CustomHighLighter);
const
  sDefaultHlSetToSelf = 'A SynMultiSyn cannot be its own DefaultHighlighter.';
begin
  if DefaultHighlighter <> Value then
  begin
    if Value = Self then
      raise Exception.Create(sDefaultHlSetToSelf);
    if DefaultHighlighter <> nil then
      UnhookHighlighter(DefaultHighlighter);
    FDefaultHighlighter := Value;
    if DefaultHighlighter <> nil then
      HookHighlighter(DefaultHighlighter);
    DefHighlightChange(Self);
  end;
end;

procedure TSynEdit32HighlighterMulti.DoCheckMarker(Scheme:TScheme; StartPos, MarkerLen: Integer;
  const MarkerText: UnicodeString; Start: Boolean; Line: Integer;
  const LineStr: string);
var
  aStartPos: Integer;
  aMarkerLen: Integer;
  aMarkerText: UnicodeString;
begin
  aStartPos := StartPos;
  aMarkerLen := MarkerLen;
  aMarkerText := MarkerText;
  if Start and Assigned(Scheme.OnCheckStartMarker) then
    Scheme.OnCheckStartMarker(Self, aStartPos, aMarkerLen, aMarkerText, Line, LineStr)
  else if not Start and Assigned(Scheme.OnCheckEndMarker) then
    Scheme.OnCheckEndMarker(Self, aStartPos, aMarkerLen, aMarkerText, Line, LineStr);
  if (aMarkerText <> '') and (aMarkerLen > 0) then
  begin
    FMarkers.Add(TMarker.Create(Scheme.Index, aStartPos, aMarkerLen, Start,
      aMarkerText));
  end;
end;

procedure TSynEdit32HighlighterMulti.SetSchemes(const Value: TSchemes);
begin
  FSchemes.Assign(Value);
end;

procedure TSynEdit32HighlighterMulti.UnhookHighlighter(aHL: TSynEdit32CustomHighLighter);
begin
  aHL.UnhookAttrChangeEvent(DefHighlightChange);
  aHL.RemoveFreeNotification(Self);
end;

function TSynEdit32HighlighterMulti.GetSampleSource: UnicodeString;
begin
  Result := FSampleSource;
end;

procedure TSynEdit32HighlighterMulti.SetSampleSource(Value: UnicodeString);
begin
  FSampleSource := Value;
end;

function TSynEdit32HighlighterMulti.LoadFromRegistry(RootKey: HKEY;
  Key: string): Boolean;
var
  r: TRegistry;
  i: Integer;
begin
  if DefaultHighlighter <> nil then
    Result := DefaultHighlighter.LoadFromRegistry(RootKey, Key + '\DefaultHighlighter')
  else
    Result := False;
  r := TRegistry.Create;
  try
    r.RootKey := RootKey;
    for i := 0 to Schemes.Count-1 do
      if (Schemes[i].SchemeName <> '') and
        r.OpenKeyReadOnly(Key + '\' + Schemes[i].SchemeName) then
      begin
        Result := Schemes[i].MarkerAttri.LoadFromRegistry(r) and Result;
        r.CloseKey;
        Result := (Schemes[i].Highlighter <> nil) and
          Schemes[i].Highlighter.LoadFromRegistry(RootKey,
          Key + '\' + Schemes[i].SchemeName) and Result;
      end
      else
        Result := False;
  finally
    r.Free;
  end;
end;

function TSynEdit32HighlighterMulti.SaveToRegistry(RootKey: HKEY; Key: string): Boolean;
var
  r: TRegistry;
  i: integer;
begin
  if DefaultHighlighter <> nil then
    Result := DefaultHighlighter.SaveToRegistry(RootKey, Key + '\DefaultHighlighter')
  else
    Result := False;
  r := TRegistry.Create;
  try
    r.RootKey := RootKey;
    for i := 0 to Schemes.Count-1 do
      if (Schemes[i].SchemeName <> '') and
        r.OpenKey(Key + '\' + Schemes[i].SchemeName, True) then
      begin
        Result := Schemes[i].MarkerAttri.SaveToRegistry(r) and Result;
        r.CloseKey;
        Result := (Schemes[i].Highlighter <> nil) and
          Schemes[i].Highlighter.SaveToRegistry(RootKey,
          Key + '\' + Schemes[i].SchemeName) and Result;
      end
      else
        Result := False;
  finally
    r.Free;
  end;
end;

function TSynEdit32HighlighterMulti.GetRange: Pointer;
begin
  Result := nil;
  FRangeProc(roGet, TRangeUNativeInt(Result));
end;

procedure TSynEdit32HighlighterMulti.SetRange(Value: Pointer);
begin
  FRangeProc(roSet, TRangeUNativeInt(Value));
end;

procedure TSynEdit32HighlighterMulti.NewRangeProc(Operation: TRangeOperation; var Range: TRangeUNativeInt);
const
  SchemeIndexSize = 3;
  MaxSchemeCount = (1 shl SchemeIndexSize) - 1;
  SchemeRangeSize = 4;
  MaxSchemeRange = (1 shl SchemeRangeSize) - 1;
begin
  if Operation = roGet then
  begin
    if DefaultHighlighter <> nil then
      Range := cardinal(DefaultHighlighter.GetRange)
    else
      Range := 0;
    if CurrScheme >= 0 then
    begin
      Assert(cardinal(Schemes[CurrScheme].Highlighter.GetRange) <= MaxSchemeRange);
      Range := Range shl SchemeRangeSize;
      Range := Range or cardinal(Schemes[CurrScheme].Highlighter.GetRange);
    end;
    Assert(CurrScheme <= MaxSchemeCount);
    Range := Range shl SchemeIndexSize;
    Range := Range or cardinal(CurrScheme + 1);
  end
  else
  begin
    CurrScheme := integer(Range and MaxSchemeCount) - 1;
    Range := Range shr SchemeIndexSize;
    if CurrScheme >= 0 then
    begin
      Schemes[CurrScheme].Highlighter.SetRange(pointer(Range and MaxSchemeRange));
      Range := Range shr SchemeRangeSize;
    end;
    if DefaultHighlighter <> nil then
    begin
      FTmpRange := pointer(Range);
      DefaultHighlighter.SetRange(FTmpRange);
    end;
  end;
end;

function TSynEdit32HighlighterMulti.UpdateRangeProcs: boolean;
// determines the appropriate RangeProcs and returns whether they were changed
var
  i: Integer;
  OldProc: TRangeProc;
begin
  OldProc := FRangeProc;
  if Assigned(OnCustomRange) then
    FRangeProc := UserRangeProc
  else
  begin
    FRangeProc := NewRangeProc;
    for i := 0 to Schemes.Count -1 do
      if Schemes[i].Highlighter is TSynEdit32HighlighterMulti then
      begin
        FRangeProc := OldRangeProc;
        break;
      end;
  end;
  Result := TMethod(OldProc).Code <> TMethod(FRangeProc).Code;
  if Result then
    DefHighlightChange(Self);
end;

procedure TSynEdit32HighlighterMulti.UserRangeProc(Operation: TRangeOperation; var Range: TRangeUNativeInt);
begin
  OnCustomRange(Self, Operation, pointer(Range));
  if (Operation = roSet) and (DefaultHighlighter <> nil) then
    FTmpRange := DefaultHighlighter.GetRange;
end;

procedure TSynEdit32HighlighterMulti.SetOnCustomRange(const Value: TCustomRangeEvent);
begin
  if (TMethod(OnCustomRange).Code <> TMethod(Value).Code) or
    (TMethod(OnCustomRange).Data <> TMethod(Value).Data) then
  begin
    FOnCustomRange := Value;
    UpdateRangeProcs;
  end;
end;

procedure TSynEdit32HighlighterMulti.Loaded;
begin
  inherited;
  DefHighlightChange(Self);
end;

function TSynEdit32HighlighterMulti.IsIdentChar(AChar: WideChar): Boolean;
begin
  if CurrScheme >= 0 then
    Result := Schemes[CurrScheme].Highlighter.IsIdentChar(AChar)
  else if DefaultHighlighter <> nil then
    Result := DefaultHighlighter.IsIdentChar(AChar)
  else
    Result := inherited IsIdentChar(AChar);
end;

class function TSynEdit32HighlighterMulti.GetFriendlyLanguageName: UnicodeString;
begin
  Result := SYNS_FriendlyLangGeneralMulti;
end;

procedure TSynEdit32HighlighterMulti.DoSetLine(const Value: UnicodeString; LineNumber: Integer);
var
  iParser: TRegExpr;
  iScheme: TScheme;
  iExpr: UnicodeString;
  iLine: UnicodeString;
  iEaten: Integer;
  i: Integer;
begin
  ClearMarkers;

  iParser := TRegExpr.Create;
  try
    iEaten := 0;
    iLine := Value;
    if CurrScheme >= 0
    then
      iScheme := FSchemes[CurrScheme]
    else
      iScheme := nil;
    while iLine <> '' do
      if iScheme <> nil then
      begin
        iParser.Expression := iScheme.EndExpr;
        iParser.ModifierI := not iScheme.CaseSensitive;
        if iParser.Exec(iLine) then
        begin
          iExpr := Copy(Value, iParser.MatchPos[0] + iEaten, iParser.MatchLen[0]);
          DoCheckMarker(iScheme, iParser.MatchPos[0] + iEaten, iParser.MatchLen[0],
            iExpr, False, LineNumber, Value);
          Delete(iLine, 1, iParser.MatchPos[0] - 1 + iParser.MatchLen[0]);
          Inc(iEaten, iParser.MatchPos[0] - 1 + iParser.MatchLen[0]);
          iScheme := nil;
        end
        else
          break;
      end
      else
      begin
        for i := 0 to Schemes.Count - 1 do
        begin
          iScheme := Schemes[i];
          if (iScheme.StartExpr = '') or (iScheme.EndExpr = '') or
            (iScheme.Highlighter = nil) or (not iScheme.Highlighter.Enabled) then
          begin
            continue;
          end;
          iParser.Expression := iScheme.StartExpr;
          iParser.ModifierI := not iScheme.CaseSensitive;
          if iParser.Exec(iLine) then
          begin
            iExpr := Copy(Value, iParser.MatchPos[0] + iEaten, iParser.MatchLen[0]);
            DoCheckMarker(iScheme, iParser.MatchPos[0] + iEaten, iParser.MatchLen[0],
              iExpr, True, LineNumber, Value);
            Delete(iLine, 1, iParser.MatchPos[0] - 1 + iParser.MatchLen[0]);
            Inc(iEaten, iParser.MatchPos[0] - 1 + iParser.MatchLen[0]);
            break;
          end;
        end; {for}
        if i >= Schemes.Count then
          break;
      end; {else}

  finally
    iParser.Free;
  end;

  FLineStr := Value;
  fLine := PWideChar(FLineStr);
  fCasedLineStr := '';
  fCasedLine := PWideChar(FLineStr);

  FMarker := nil;
  FRun := 0;
  FExpandedRun := 0;
  fOldRun := FRun;
  fTokenPos := 0;
  fExpandedTokenPos := 0;
  FNextMarker := 0;
  FLineNumber := LineNumber;
end;

function TSynEdit32HighlighterMulti.GetExpandedToken: UnicodeString;
begin
  if (DefaultHighlighter = nil) and (fExpandedLine <> nil) then
    Result := fExpandedLineStr
  else
    Result := inherited GetExpandedToken;
end;

{ TSchemes }

constructor TSchemes.Create(aOwner: TSynEdit32HighlighterMulti);
begin
  inherited Create(TScheme);
  FOwner := aOwner;
end;

function TSchemes.GetItems(Index: Integer): TScheme;
begin
  Result := inherited Items[Index] as TScheme;
end;

function TSchemes.GetOwner: TPersistent;
begin
  Result := FOwner;
end;

procedure TSchemes.SetItems(Index: Integer; const Value: TScheme);
begin
  inherited Items[Index] := Value;
end;

procedure TSchemes.Update(Item: TCollectionItem);
begin
  if Item <> nil then
    FOwner.DefHighlightChange(Item)
  else // pass the MultiSyn as the Sender so Editors reparse their text
    FOwner.DefHighlightChange(FOwner);
end;


{ TScheme }

function TScheme.ConvertExpression(const Value: UnicodeString): UnicodeString;
begin
  if not CaseSensitive then
    Result := SynWideUpperCase(Value)
  else
    Result := Value;
end;

constructor TScheme.Create(Collection: TCollection);
begin
  inherited Create(Collection);
  FCaseSensitive := True;
  FMarkerAttri := TSynEdit32HighlighterAttributes.Create(SYNS_AttrMarker, SYNS_FriendlyAttrMarker);
  FMarkerAttri.OnChange := MarkerAttriChanged;
  MarkerAttri.Background := clYellow;
  MarkerAttri.Style := [fsBold];
  MarkerAttri.InternalSaveDefaultValues;
end;

destructor TScheme.Destroy;
begin
  { unhook notification handlers }
  Highlighter := nil;
  inherited Destroy;
  FMarkerAttri.Free;
end;

function TScheme.GetDisplayName: string;
begin
  if SchemeName <> '' then
    Result := SchemeName
  else
    Result := inherited GetDisplayName;
end;

procedure TScheme.MarkerAttriChanged(Sender: TObject);
begin
  Changed(False);
end;

procedure TScheme.SetCaseSensitive(const Value: Boolean);
begin
  if FCaseSensitive <> Value then
  begin
    FCaseSensitive := Value;
    Changed(True);
  end;
end;

procedure TScheme.SetDisplayName(const Value: string);
begin
  SchemeName := Value;
end;

procedure TScheme.SetEndExpr(const Value: UnicodeString);
var
  OldValue: UnicodeString;
begin
  if FEndExpr <> Value then
  begin
    if Value <> '' then
      CheckExpression(Value);
    OldValue := FEndExpr;
    FEndExpr := Value;
    if ConvertExpression(OldValue) <> ConvertExpression(Value) then
      Changed(True);
  end;
end;

procedure TScheme.SetHighlighter(const Value: TSynEdit32CustomHighLighter);
var
  iOwner: TSynEdit32HighlighterMulti;
  iAlreadyRepainted: Boolean;
begin
  if Highlighter <> Value then
  begin
    iOwner := TSchemes(Collection).FOwner;
    if (Highlighter <> nil) and (Highlighter <> iOwner) then
      iOwner.UnhookHighlighter(Highlighter);
    FHighlighter := Value;
    if (Highlighter <> nil) and (Highlighter <> iOwner) then
      iOwner.HookHighlighter(Highlighter);
    if Highlighter is TSynEdit32HighlighterMulti then
      iAlreadyRepainted := iOwner.UpdateRangeProcs
    else
      iAlreadyRepainted := False;
    if not iAlreadyRepainted then
      Changed(True);
  end;
end;

procedure TScheme.SetMarkerAttri(const Value: TSynEdit32HighlighterAttributes);
begin
  FMarkerAttri.Assign(Value);
end;

procedure TScheme.SetStartExpr(const Value: UnicodeString);
var
  OldValue: UnicodeString;
begin
  if FStartExpr <> Value then
  begin
    if Value <> '' then
      CheckExpression(Value);
    OldValue := FStartExpr;
    FStartExpr := Value;
    if ConvertExpression(Value) <> ConvertExpression(OldValue) then
      Changed(True);
  end;
end;

end.
