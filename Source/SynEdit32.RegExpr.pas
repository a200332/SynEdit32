unit SynEdit32.RegExpr;

{
     TRegExpr class library
     Delphi Regular Expressions

 Copyright (c) 1999-2004 Andrey V. Sorokin, St.Petersburg, Russia

 You may use this software in any kind of development,
 including comercial, redistribute, and modify it freely,
 under the following restrictions :
 1. This software is provided as it is, without any kind of
    warranty given. Use it at Your own risk.The author is not
    responsible for any consequences of use of this software.
 2. The origin of this software may not be mispresented, You
    must not claim that You wrote the original software. If
    You use this software in any kind of product, it would be
    appreciated that there in a information box, or in the
    documentation would be an acknowledgement like

     Partial Copyright (c) 2004 Andrey V. Sorokin
                                http://RegExpStudio.com
                                mailto:anso@mail.ru

 3. You may not have any income from distributing this source
    (or altered version of it) to other developers. When You
    use this product in a comercial package, the source may
    not be charged seperatly.
 4. Altered versions must be plainly marked as such, and must
    not be misrepresented as being the original software.
 5. RegExp Studio application and all the visual components as
    well as documentation is not part of the TRegExpr library
    and is not free for usage.

                                    mailto:anso@mail.ru
                                    http://RegExpStudio.com
                                    http://anso.da.ru/
}

interface

{$INCLUDE SynEdit32.Inc}

// ======== Determine compiler
{$IFDEF VER80} Sorry, TRegExpr is for 32-bits Delphi only. Delphi 1 is not supported (and whos really care today?!). {$ENDIF}

// ======== Define base compiler options
{$BOOLEVAL OFF}
{$EXTENDEDSYNTAX ON}
{$LONGSTRINGS ON}
{$OPTIMIZATION ON}
{$WARN SYMBOL_PLATFORM OFF} // Suppress .Net warnings
{$WARN UNSAFE_CAST OFF} // Suppress .Net warnings
{$WARN UNSAFE_TYPE OFF} // Suppress .Net warnings
{$WARN UNSAFE_CODE OFF} // Suppress .Net warnings
{$IFDEF FPC}
  {$MODE DELPHI} // Delphi-compatible mode in FreePascal
{$ENDIF}

// ======== Define options for TRegExpr engine
{$DEFINE SynRegUniCode} // Unicode support
{$DEFINE RegExpPCodeDump} // p-code dumping (see Dump method)
{$IFNDEF FPC} // the option is not supported in FreePascal
 {$DEFINE reRealExceptionAddr} // exceptions will point to appropriate source line, not to Error procedure
{$ENDIF}
{$DEFINE ComplexBraces} // support braces in complex cases
{$IFNDEF SynRegUniCode} // the option applicable only for non-UniCode mode
 {$DEFINE UseSetOfChar} // Significant optimization by using set of char
{$ENDIF}
{$IFDEF UseSetOfChar}
 {$DEFINE UseFirstCharSet} // Fast skip between matches for r.e. that starts with determined set of chars
{$ENDIF}

// ======== Define Pascal-language options
// Define 'UseAsserts' option (do not edit this definitions).
// Asserts used to catch 'strange bugs' in TRegExpr implementation (when something goes
// completely wrong). You can swith asserts on/off with help of {$C+}/{$C-} compiler options.
{$DEFINE UseAsserts}
{$IFDEF FPC} {$DEFINE UseAsserts} {$ENDIF}

// Define 'use subroutine parameters default values' option (do not edit this definition).
{$DEFINE DefParam}

// Define 'OverMeth' options, to use method overloading (do not edit this definitions).
{$DEFINE OverMeth}
{$IFDEF FPC} {$DEFINE OverMeth} {$ENDIF}

uses
  Classes,  // TStrings in Split method
  SysUtils, SynEdit32.Unicode; // Exception

type
  {$IFDEF SynRegUniCode}
  PRegExprChar = PWideChar;
  RegExprString = UnicodeString;
  REChar = WideChar;
  {$ELSE}
  PRegExprChar = PChar;
  RegExprString = AnsiString; //###0.952 was string
  REChar = Char;
  {$ENDIF}
  TREOp = REChar; // internal p-code type //###0.933
  PREOp = ^TREOp;
  TRENextOff = Integer; // internal Next "pointer" (offset to current p-code) //###0.933
  PRENextOff = ^TRENextOff; // used for extracting Next "pointers" from compiled r.e. //###0.933
  TREBracesArg = Integer; // type of {m,n} arguments
  PREBracesArg = ^TREBracesArg;

const
  REOpSz = SizeOf (TREOp) div SizeOf (REChar); // size of p-code in RegExprString units
  RENextOffSz = SizeOf (TRENextOff) div SizeOf (REChar); // size of Next 'pointer' -"-
  REBracesArgSz = SizeOf (TREBracesArg) div SizeOf (REChar); // size of BRACES arguments -"-

type
  TRegExprInvertCaseFunction = function (const Ch: REChar): REChar of object;

const
  EscChar = '\'; // 'Escape'-char ('\' in common r.e.) used for escaping metachars (\w, \d etc).
  RegExprModifierI : Boolean = False;    // default value for ModifierI
  RegExprModifierR : Boolean = True;     // default value for ModifierR
  RegExprModifierS : Boolean = True;     // default value for ModifierS
  RegExprModifierG : Boolean = True;     // default value for ModifierG
  RegExprModifierM : Boolean = False;    // default value for ModifierM
  RegExprModifierX : Boolean = False;    // default value for ModifierX
  RegExprSpaceChars : RegExprString =    // default value for SpaceChars
  ' '#$9#$A#$D#$C;
  RegExprWordChars : RegExprString =     // default value for WordChars
    '0123456789' //###0.940
  + 'abcdefghijklmnopqrstuvwxyz'
  + 'ABCDEFGHIJKLMNOPQRSTUVWXYZ_';
  RegExprLineSeparators : RegExprString =// default value for LineSeparators
   #$d#$a{$IFDEF SynRegUniCode}+#$b#$c#$2028#$2029#$85{$ENDIF}; //###0.947
  RegExprLinePairedSeparator : RegExprString =// default value for LinePairedSeparator
   #$d#$a;
  { if You need Unix-styled line separators (only \n), then use:
  RegExprLineSeparators = #$a;
  RegExprLinePairedSeparator = '';
  }


const
  NSUBEXP = 15; // max number of subexpression //###0.929
  // Cannot be more than NSUBEXPMAX
  // Be carefull - don't use values which overflow CLOSE opcode
  // (in this case you'll get compiler erorr).
  // Big NSUBEXP will cause more slow work and more stack required
  NSUBEXPMAX = 255; // Max possible value for NSUBEXP. //###0.945
  // Don't change it! It's defined by internal TRegExpr design.

  MaxBracesArg = $7FFFFFFF - 1; // max value for {n,m} arguments //###0.933

  {$IFDEF ComplexBraces}
  LoopStackMax = 10; // max depth of loops stack //###0.925
  {$ENDIF}

  TinySetLen = 3;
  // if range includes more then TinySetLen chars, //###0.934
  // then use full (32 bytes) ANYOFFULL instead of ANYOF[BUT]TINYSET
  // !!! Attension ! If you change TinySetLen, you must
  // change code marked as "//!!!TinySet"

type
{$IFDEF UseSetOfChar}
  PSetOfREChar = ^TSetOfREChar;
  TSetOfREChar = set of REChar;
{$ENDIF}

  TRegExpr = class;

  TRegExprReplaceFunction = function (ARegExpr : TRegExpr): string of object;

  TRegExpr = class
  private
    startp : array [0 .. NSUBEXP - 1] of PRegExprChar; // founded expr starting points
    endp : array [0 .. NSUBEXP - 1] of PRegExprChar; // founded expr end points

    {$IFDEF ComplexBraces}
    LoopStack : array [1 .. LoopStackMax] of Integer; // state before entering loop
    LoopStackIdx : Integer; // 0 - out of all loops
    {$ENDIF}

    // The "internal use only" fields to pass info from compile
    // to execute that permits the execute phase to run lots faster on
    // simple cases.
    regstart : REChar; // char that must begin a match; '\0' if none obvious
    reganch : REChar; // is the match anchored (at beginning-of-line only)?
    regmust : PRegExprChar; // string (pointer into program) that match must include, or nil
    regmlen : Integer; // length of regmust string
    // Regstart and reganch permit very fast decisions on suitable starting points
    // for a match, cutting down the work a lot.  Regmust permits fast rejection
    // of lines that cannot possibly match.  The regmust tests are costly enough
    // that regcomp() supplies a regmust only if the r.e. contains something
    // potentially expensive (at present, the only such thing detected is * or +
    // at the start of the r.e., which can involve a lot of backup).  Regmlen is
    // supplied because the test in regexec() needs it and regcomp() is computing
    // it anyway.
    {$IFDEF UseFirstCharSet} //###0.929
    FFirstCharSet : TSetOfREChar;
    {$ENDIF}

    // work variables for Exec's routins - save stack in recursion}
    FRegInput : PRegExprChar; // String-input pointer.
    FInputStart : PRegExprChar; // Pointer to first char of input string.
    FInputEnd : PRegExprChar; // Pointer to char AFTER last char of input string

    // work variables for compiler's routines
    FRegParse : PRegExprChar;  // Input-scan pointer.
    FRegnpar : Integer; // count.
    FRegdummy : REChar;
    FRegcode : PRegExprChar;   // Code-emit pointer; @FRegdummy = don't.
    FRegsize : Integer; // Code size.

    FRegexpbeg : PRegExprChar; // only for error handling. Contains
    // pointer to beginning of r.e. while compiling
    FExprIsCompiled : Boolean; // True if r.e. successfully compiled

    // FProgramm is essentially a linear encoding
    // of a nondeterministic finite-state machine (aka syntax charts or
    // "railroad normal form" in parsing technology).  Each node is an opcode
    // plus a "next" pointer, possibly plus an operand.  "Next" pointers of
    // all nodes except BRANCH implement concatenation; a "next" pointer with
    // a BRANCH on both ends of it is connecting two alternatives.  (Here we
    // have one of the subtle syntax dependencies:  an individual BRANCH (as
    // opposed to a collection of them) is never concatenated with anything
    // because of operator precedence.)  The operand of some types of node is
    // a literal string; for others, it is a node leading into a sub-FSM.  In
    // particular, the operand of a BRANCH node is the first node of the branch.
    // (NB this is *not* a tree structure:  the tail of the branch connects
    // to the thing following the set of BRANCHes.)  The opcodes are:
    FProgramm : PRegExprChar; // Unwarranted chumminess with compiler.

    FExpression : PRegExprChar; // source of compiled r.e.
    FInputString : PRegExprChar; // input string

    FLastError : Integer; // see Error, LastError

    FModifiers : Integer; // modifiers
    FCompModifiers : Integer; // compiler's copy of modifiers
    FProgModifiers : Integer; // modifiers values from last FProgramm compilation

    FSpaceChars : RegExprString; //###0.927
    FWordChars : RegExprString; //###0.929
    FInvertCase : TRegExprInvertCaseFunction; //###0.927

    FLineSeparators : RegExprString; //###0.941
    FLinePairedSeparatorAssigned : Boolean;
    FLinePairedSeparatorHead,
    FLinePairedSeparatorTail : REChar;
    {$IFNDEF SynRegUniCode}
    FLineSeparatorsSet : set of REChar;
    {$ENDIF}

    procedure InvalidateProgramm;
    // Mark FProgramm as have to be [re]compiled

    function IsProgrammOk : Boolean; //###0.941
    // Check if we can use precompiled r.e. or
    // [re]compile it if something changed

    function GetExpression : RegExprString;
    procedure SetExpression (const s : RegExprString);

    function GetModifierStr : RegExprString;
    class function ParseModifiersStr (const AModifiers : RegExprString;
      var AModifiersInt : Integer) : Boolean; //###0.941 class function now
    // Parse AModifiers string and return True and set AModifiersInt
    // if it's in format 'ismxrg-ismxrg'.
    procedure SetModifierStr (const AModifiers : RegExprString);

    function GetModifier (AIndex : Integer) : Boolean;
    procedure SetModifier (AIndex : Integer; ASet : Boolean);

    procedure Error (AErrorID : Integer); virtual; // error handler.
    // Default handler raise exception ERegExpr with
    // Message = ErrorMsg (AErrorID), ErrorCode = AErrorID
    // and CompilerErrorPos = value of property CompilerErrorPos.


    {==================== Compiler section ===================}
    function CompileRegExpr (exp : PRegExprChar) : Boolean;
    // compile a regular expression into internal code

    procedure Tail (p : PRegExprChar; val : PRegExprChar);
    // set the next-pointer at the end of a node chain

    procedure OpTail (p : PRegExprChar; val : PRegExprChar);
    // regoptail - regtail on operand of first argument; nop if operandless

    function EmitNode (op : TREOp) : PRegExprChar;
    // regnode - emit a node, return location

    procedure EmitC (b : REChar);
    // emit (if appropriate) a byte of code

    procedure InsertOperator (op : TREOp; opnd : PRegExprChar; sz : Integer); //###0.90
    // insert an operator in front of already-emitted operand
    // Means relocating the operand.

    function ParseReg (paren : Integer; var flagp : Integer) : PRegExprChar;
    // regular expression, i.e. main body or parenthesized thing

    function ParseBranch (var flagp : Integer) : PRegExprChar;
    // one alternative of an | operator

    function ParsePiece (var flagp : Integer) : PRegExprChar;
    // something followed by possible [*+?]

    function ParseAtom (var flagp : Integer) : PRegExprChar;
    // the lowest level

    function GetCompilerErrorPos : Integer;
    // current pos in r.e. - for error hanling

    {$IFDEF UseFirstCharSet} //###0.929
    procedure FillFirstCharSet (prog : PRegExprChar);
    {$ENDIF}

    {===================== Mathing section ===================}
    function regrepeat (p : PRegExprChar; AMax : Integer) : Integer;
    // repeatedly match something simple, report how many

    function regnext (p : PRegExprChar) : PRegExprChar;
    // dig the "next" pointer out of a node

    function MatchPrim (prog : PRegExprChar) : Boolean;
    // recursively matching routine

    function ExecPrim (AOffset: Integer) : Boolean;
    // Exec for stored InputString

    {$IFDEF RegExpPCodeDump}
    function DumpOp (op : REChar) : RegExprString;
    {$ENDIF}

    function GetSubExprMatchCount : Integer;
    function GetMatchPos (Idx : Integer) : Integer;
    function GetMatchLen (Idx : Integer) : Integer;
    function GetMatch (Idx : Integer) : RegExprString;

    function GetInputString : RegExprString;
    procedure SetInputString (const AInputString : RegExprString);

    {$IFNDEF UseSetOfChar}
    function StrScanCI (s : PRegExprChar; ch : REChar) : PRegExprChar; //###0.928
    {$ENDIF}

    procedure SetLineSeparators (const AStr : RegExprString);
    procedure SetLinePairedSeparator (const AStr : RegExprString);
    function GetLinePairedSeparator : RegExprString;

  public
    constructor Create;
    destructor Destroy; override;

    class function VersionMajor : Integer; //###0.944
    class function VersionMinor : Integer; //###0.944

    property Expression : RegExprString read GetExpression write SetExpression;
    // Regular expression.
    // For optimization, TRegExpr will automatically compiles it into 'P-code'
    // (You can see it with help of Dump method) and stores in internal
    // structures. Real [re]compilation occures only when it really needed -
    // while calling Exec[Next], Substitute, Dump, etc
    // and only if Expression or other P-code affected properties was changed
    // after last [re]compilation.
    // If any errors while [re]compilation occures, Error method is called
    // (by default Error raises exception - see below)

    property ModifierStr : RegExprString read GetModifierStr write SetModifierStr;
    // Set/get default values of r.e.syntax modifiers. Modifiers in
    // r.e. (?ismx-ismx) will replace this default values.
    // If you try to set unsupported modifier, Error will be called
    // (by defaul Error raises exception ERegExpr).

    property ModifierI : Boolean index 1 read GetModifier write SetModifier;
    // Modifier /i - caseinsensitive, initialized from RegExprModifierI

    property ModifierR : Boolean index 2 read GetModifier write SetModifier;
    // Modifier /r - use r.e.syntax extended for russian,
    // (was property ExtSyntaxEnabled in previous versions)
    // If True, then �-�  additional include russian letter '�',
    // �-�  additional include '�', and �-� include all russian symbols.
    // You have to turn it off if it may interfere with you national alphabet.
    // , initialized from RegExprModifierR

    property ModifierS : Boolean index 3 read GetModifier write SetModifier;
    // Modifier /s - '.' works as any char (else as [^\n]),
    // , initialized from RegExprModifierS

    property ModifierG : Boolean index 4 read GetModifier write SetModifier;
    // Switching off modifier /g switchs all operators in
    // non-greedy style, so if ModifierG = False, then
    // all '*' works as '*?', all '+' as '+?' and so on.
    // , initialized from RegExprModifierG

    property ModifierM : Boolean index 5 read GetModifier write SetModifier;
    // Treat string as multiple lines. That is, change `^' and `$' from
    // matching at only the very start or end of the string to the start
    // or end of any line anywhere within the string.
    // , initialized from RegExprModifierM

    property ModifierX : Boolean index 6 read GetModifier write SetModifier;
    // Modifier /x - eXtended syntax, allow r.e. text formatting,
    // see description in the help. Initialized from RegExprModifierX

    function Exec (const AInputString : RegExprString) : Boolean; {$IFDEF OverMeth} overload;
    {$IFNDEF FPC} // I do not know why FreePascal cannot overload methods with empty param list
    function Exec : Boolean; overload; //###0.949
    {$ENDIF}
    function Exec (AOffset: Integer) : Boolean; overload; //###0.949
    {$ENDIF}
    // match a FProgramm against a string AInputString
    // !!! Exec store AInputString into InputString property
    // For Delphi 5 and higher available overloaded versions - first without
    // parameter (uses already assigned to InputString property value)
    // and second that has Integer parameter and is same as ExecPos

    function ExecNext : Boolean;
    // find next match:
    //    ExecNext;
    // works same as
    //    if MatchLen [0] = 0 then ExecPos (MatchPos [0] + 1)
    //     else ExecPos (MatchPos [0] + MatchLen [0]);
    // but it's more simpler !
    // Raises exception if used without preceeding SUCCESSFUL call to
    // Exec* (Exec, ExecPos, ExecNext). So You always must use something like
    // if Exec (InputString) then repeat { proceed results} until not ExecNext;

    function ExecPos (AOffset: Integer {$IFDEF DefParam}= 1{$ENDIF}) : Boolean;
    // find match for InputString starting from AOffset position
    // (AOffset=1 - first char of InputString)

    property InputString : RegExprString read GetInputString write SetInputString;
    // returns current input string (from last Exec call or last assign
    // to this property).
    // Any assignment to this property clear Match* properties !

    function Substitute (const ATemplate : RegExprString) : RegExprString;
    // Returns ATemplate with '$&' or '$0' replaced by whole r.e.
    // occurence and '$n' replaced by occurence of subexpression #n.
    // Since v.0.929 '$' used instead of '\' (for future extensions
    // and for more Perl-compatibility) and accept more then one digit.
    // If you want place into template raw '$' or '\', use prefix '\'
    // Example: '1\$ is $2\\rub\\' -> '1$ is <Match[2]>\rub\'
    // If you want to place raw digit after '$n' you must delimit
    // n with curly braces '{}'.
    // Example: 'a$12bc' -> 'a<Match[12]>bc'
    // 'a${1}2bc' -> 'a<Match[1]>2bc'.

    procedure Split (AInputStr : RegExprString; APieces : TStrings);
    // Split AInputStr into APieces by r.e. occurencies
    // Internally calls Exec[Next]

    function Replace (AInputStr : RegExprString;
      const AReplaceStr : RegExprString;
      AUseSubstitution : Boolean{$IFDEF DefParam}= False{$ENDIF}) //###0.946
     : RegExprString; {$IFDEF OverMeth} overload;
    function Replace (AInputStr : RegExprString;
      AReplaceFunc : TRegExprReplaceFunction)
     : RegExprString; overload;
    {$ENDIF}
    function ReplaceEx (AInputStr : RegExprString;
      AReplaceFunc : TRegExprReplaceFunction)
     : RegExprString;
    // Returns AInputStr with r.e. occurencies replaced by AReplaceStr
    // If AUseSubstitution is True, then AReplaceStr will be used
    // as template for Substitution methods.
    // For example:
    //  Expression := '({-i}block|var)\s*\(\s*([^ ]*)\s*\)\s*';
    //  Replace ('BLOCK( test1)', 'def "$1" value "$2"', True);
    //   will return:  def 'BLOCK' value 'test1'
    //  Replace ('BLOCK( test1)', 'def "$1" value "$2"')
    //   will return:  def "$1" value "$2"
    // Internally calls Exec[Next]
    // Overloaded version and ReplaceEx operate with call-back function,
    // so You can implement really complex functionality.

    property SubExprMatchCount : Integer read GetSubExprMatchCount;
    // Number of subexpressions has been found in last Exec* call.
    // If there are no subexpr. but whole expr was found (Exec* returned True),
    // then SubExprMatchCount=0, if no subexpressions nor whole
    // r.e. found (Exec* returned False) then SubExprMatchCount=-1.
    // Note, that some subexpr. may be not found and for such
    // subexpr. MathPos=MatchLen=-1 and Match=''.
    // For example: Expression := '(1)?2(3)?';
    //  Exec ('123'): SubExprMatchCount=2, Match[0]='123', [1]='1', [2]='3'
    //  Exec ('12'): SubExprMatchCount=1, Match[0]='12', [1]='1'
    //  Exec ('23'): SubExprMatchCount=2, Match[0]='23', [1]='', [2]='3'
    //  Exec ('2'): SubExprMatchCount=0, Match[0]='2'
    //  Exec ('7') - return False: SubExprMatchCount=-1

    property MatchPos [Idx : Integer] : Integer read GetMatchPos;
    // pos of entrance subexpr. #Idx into tested in last Exec*
    // string. First subexpr. have Idx=1, last - MatchCount,
    // whole r.e. have Idx=0.
    // Returns -1 if in r.e. no such subexpr. or this subexpr.
    // not found in input string.

    property MatchLen [Idx : Integer] : Integer read GetMatchLen;
    // len of entrance subexpr. #Idx r.e. into tested in last Exec*
    // string. First subexpr. have Idx=1, last - MatchCount,
    // whole r.e. have Idx=0.
    // Returns -1 if in r.e. no such subexpr. or this subexpr.
    // not found in input string.
    // Remember - MatchLen may be 0 (if r.e. match empty string) !

    property Match [Idx : Integer] : RegExprString read GetMatch;
    // == copy (InputString, MatchPos [Idx], MatchLen [Idx])
    // Returns '' if in r.e. no such subexpr. or this subexpr.
    // not found in input string.

    function LastError : Integer;
    // Returns ID of last error, 0 if no errors (unusable if
    // Error method raises exception) and clear internal status
    // into 0 (no errors).

    function ErrorMsg (AErrorID : Integer) : RegExprString; virtual;
    // Returns Error message for error with ID = AErrorID.

    property CompilerErrorPos : Integer read GetCompilerErrorPos;
    // Returns pos in r.e. there compiler stopped.
    // Usefull for error diagnostics

    property SpaceChars : RegExprString read FSpaceChars write FSpaceChars; //###0.927
    // Contains chars, treated as /s (initially filled with RegExprSpaceChars
    // global constant)

    property WordChars : RegExprString read FWordChars write FWordChars; //###0.929
    // Contains chars, treated as /w (initially filled with RegExprWordChars
    // global constant)

    property LineSeparators : RegExprString read FLineSeparators write SetLineSeparators; //###0.941
    // line separators (like \n in Unix)

    property LinePairedSeparator : RegExprString read GetLinePairedSeparator write SetLinePairedSeparator; //###0.941
    // paired line separator (like \r\n in DOS and Windows).
    // must contain exactly two chars or no chars at all

    class function InvertCaseFunction  (const Ch : REChar) : REChar;
    // Converts Ch into upper case if it in lower case or in lower
    // if it in upper (uses current system local setings)

    property InvertCase : TRegExprInvertCaseFunction read FInvertCase write FInvertCase; //##0.935
    // Set this property if you want to override case-insensitive functionality.
    // Create set it to RegExprInvertCaseFunction (InvertCaseFunction by default)

    procedure Compile; //###0.941
    // [Re]compile r.e. Usefull for example for GUI r.e. editors (to check
    // all properties validity).

    {$IFDEF RegExpPCodeDump}
    function Dump : RegExprString;
    // dump a compiled regexp in vaguely comprehensible form
    {$ENDIF}
  end;

  ERegExpr = class (Exception)
  public
    ErrorCode : Integer;
    CompilerErrorPos : Integer;
  end;

const
  RegExprInvertCaseFunction : TRegExprInvertCaseFunction = {$IFDEF FPC} nil {$ELSE} TRegExpr.InvertCaseFunction{$ENDIF};
  // defaul for InvertCase property

function ExecRegExpr (const ARegExpr, AInputStr : RegExprString) : Boolean;
// True if string AInputString match regular expression ARegExpr
// ! will raise exeption if syntax errors in ARegExpr

procedure SplitRegExpr (const ARegExpr, AInputStr : RegExprString; APieces : TStrings);
// Split AInputStr into APieces by r.e. ARegExpr occurencies

function ReplaceRegExpr (const ARegExpr, AInputStr, AReplaceStr : RegExprString;
      AUseSubstitution : Boolean{$IFDEF DefParam}= False{$ENDIF}) : RegExprString; //###0.947
// Returns AInputStr with r.e. occurencies replaced by AReplaceStr
// If AUseSubstitution is True, then AReplaceStr will be used
// as template for Substitution methods.
// For example:
//  ReplaceRegExpr ('({-i}block|var)\s*\(\s*([^ ]*)\s*\)\s*',
//   'BLOCK( test1)', 'def "$1" value "$2"', True)
//  will return:  def 'BLOCK' value 'test1'
//  ReplaceRegExpr ('({-i}block|var)\s*\(\s*([^ ]*)\s*\)\s*',
//   'BLOCK( test1)', 'def "$1" value "$2"')
//   will return:  def "$1" value "$2"

function QuoteRegExprMetaChars (const AStr : RegExprString) : RegExprString;
// Replace all metachars with its safe representation,
// for example 'abc$cd.(' converts into 'abc\$cd\.\('
// This function usefull for r.e. autogeneration from
// user input

function RegExprSubExpressions (const ARegExpr : string;
 ASubExprs : TStrings; AExtendedSyntax : Boolean{$IFDEF DefParam}= False{$ENDIF}) : Integer;
// Makes list of subexpressions found in ARegExpr r.e.
// In ASubExps every item represent subexpression,
// from first to last, in format:
//  String - subexpression text (without '()')
//  low word of Object - starting position in ARegExpr, including '('
//   if exists! (first position is 1)
//  high word of Object - length, including starting '(' and ending ')'
//   if exist!
// AExtendedSyntax - must be True if modifier /m will be On while
// using the r.e.
// Usefull for GUI editors of r.e. etc (You can find example of using
// in TestRExp.dpr project)
// Returns
//  0      Success. No unbalanced brackets was found;
//  -1     There are not enough closing brackets ')';
//  -(n+1) At position n was found opening '[' without  //###0.942
//         corresponding closing ']';
//  n      At position n was found closing bracket ')' without
//         corresponding opening '('.
// If Result <> 0, then ASubExpr can contain empty items or illegal ones


implementation

uses
  Windows; // CharUpper/Lower

const
  TRegExprVersionMajor : Integer = 0;
  TRegExprVersionMinor : Integer = 952;
  // TRegExpr.VersionMajor/Minor return values of this constants

  MaskModI = 1;  // modifier /i bit in FModifiers
  MaskModR = 2;  // -"- /r
  MaskModS = 4;  // -"- /s
  MaskModG = 8;  // -"- /g
  MaskModM = 16; // -"- /m
  MaskModX = 32; // -"- /x

{$IFDEF SynRegUniCode}
  XIgnoredChars = ' '#9#$d#$a;
{$ELSE}
  XIgnoredChars = [' ', #9, #$d, #$a];
{$ENDIF}

{=============================================================}
{=================== UnicodeString functions ====================}
{=============================================================}

{$IFDEF SynRegUniCode}

function StrPCopy (Dest: PRegExprChar; const Source: RegExprString): PRegExprChar;
 var
  i, Len : Integer;
 begin
  Len := length (Source); //###0.932
  for i := 1 to Len do
   Dest [i - 1] := Source [i];
  Dest [Len] := #0;
  Result := Dest;
 end; { of function StrPCopy
--------------------------------------------------------------}

function StrLCopy (Dest, Source: PRegExprChar; MaxLen: Cardinal): PRegExprChar;
 var i: Integer;
 begin
  for i := 0 to MaxLen - 1 do
   Dest [i] := Source [i];
  Result := Dest;
 end; { of function StrLCopy
--------------------------------------------------------------}

function StrLen (Str: PRegExprChar): Cardinal;
 begin
  Result:=0;
  while Str [result] <> #0
   do Inc (Result);
 end; { of function StrLen
--------------------------------------------------------------}

function StrPos (Str1, Str2: PRegExprChar): PRegExprChar;
 var n: Integer;
 begin
  Result := nil;
  n := Pos (RegExprString (Str2), RegExprString (Str1));
  if n = 0
   then Exit;
  Result := Str1 + n - 1;
 end; { of function StrPos
--------------------------------------------------------------}

function StrLComp (Str1, Str2: PRegExprChar; MaxLen: Cardinal): Integer;
 var S1, S2: RegExprString;
 begin
  S1 := Str1;
  S2 := Str2;
  if Copy (S1, 1, MaxLen) > Copy (S2, 1, MaxLen)
   then Result := 1
   else
    if Copy (S1, 1, MaxLen) < Copy (S2, 1, MaxLen)
     then Result := -1
     else Result := 0;
 end; { function StrLComp
--------------------------------------------------------------}

function StrScan (Str: PRegExprChar; Chr: WideChar): PRegExprChar;
 begin
  Result := nil;
  while (Str^ <> #0) and (Str^ <> Chr)
   do Inc (Str);
  if (Str^ <> #0)
   then Result := Str;
 end; { of function StrScan
--------------------------------------------------------------}

{$ENDIF}


{=============================================================}
{===================== Global functions ======================}
{=============================================================}

function ExecRegExpr (const ARegExpr, AInputStr : RegExprString) : Boolean;
 var r : TRegExpr;
 begin
  r := TRegExpr.Create;
  try
    r.Expression := ARegExpr;
    Result := r.Exec (AInputStr);
    finally r.Free;
   end;
 end; { of function ExecRegExpr
--------------------------------------------------------------}

procedure SplitRegExpr (const ARegExpr, AInputStr : RegExprString; APieces : TStrings);
 var r : TRegExpr;
 begin
  APieces.Clear;
  r := TRegExpr.Create;
  try
    r.Expression := ARegExpr;
    r.Split (AInputStr, APieces);
    finally r.Free;
   end;
 end; { of procedure SplitRegExpr
--------------------------------------------------------------}

function ReplaceRegExpr (const ARegExpr, AInputStr, AReplaceStr : RegExprString;
      AUseSubstitution : Boolean{$IFDEF DefParam}= False{$ENDIF}) : RegExprString;
 begin
  with TRegExpr.Create do try
    Expression := ARegExpr;
    Result := Replace (AInputStr, AReplaceStr, AUseSubstitution);
    finally Free;
   end;
 end; { of function ReplaceRegExpr
--------------------------------------------------------------}

function QuoteRegExprMetaChars (const AStr : RegExprString) : RegExprString;
 const
  RegExprMetaSet : RegExprString = '^$.[()|?+*'+EscChar+'{'
  + ']}'; // - this last are additional to META.
  // Very similar to META array, but slighly changed.
  // !Any changes in META array must be synchronized with this set.
 var
  i, i0, Len : Integer;
 begin
  Result := '';
  Len := length (AStr);
  i := 1;
  i0 := i;
  while i <= Len do
  begin
    if Pos (AStr [i], RegExprMetaSet) > 0 then
    begin
      Result := Result + System.Copy (AStr, i0, i - i0)
                 + EscChar + AStr [i];
      i0 := i + 1;
     end;
    Inc (i);
   end;
  Result := Result + System.Copy (AStr, i0, MaxInt); // Tail
 end; { of function QuoteRegExprMetaChars
--------------------------------------------------------------}

function RegExprSubExpressions (const ARegExpr : string;
 ASubExprs : TStrings; AExtendedSyntax : Boolean{$IFDEF DefParam}= False{$ENDIF}) : Integer;
 type
  TStackItemRec =  record //###0.945
    SubExprIdx : Integer;
    StartPos : Integer;
   end;
  TStackArray = packed array [0 .. NSUBEXPMAX - 1] of TStackItemRec;
 var
  Len, SubExprLen : Integer;
  i, i0 : Integer;
  Modif : Integer;
  Stack : ^TStackArray; //###0.945
  StackIdx, StackSz : Integer;
 begin
  Result := 0; // no unbalanced brackets found at this very moment

  ASubExprs.Clear; // I don't think that adding to non empty list
  // can be usefull, so I simplified algorithm to work only with empty list

  Len := length (ARegExpr); // some optimization tricks

  // first we have to calculate number of subexpression to reserve
  // space in Stack array (may be we'll reserve more then need, but
  // it's faster then memory reallocation during parsing)
  StackSz := 1; // add 1 for entire r.e.
  for i := 1 to Len do
   if ARegExpr [i] = '('
    then Inc (StackSz);
//  SetLength (Stack, StackSz); //###0.945
  GetMem (Stack, SizeOf (TStackItemRec) * StackSz);
  try

  StackIdx := 0;
  i := 1;
  while (i <= Len) do
  begin
    case ARegExpr [i] of
      '(': begin
        if (i < Len) and (ARegExpr [i + 1] = '?') then
        begin
           // this is not subexpression, but comment or other
           // Perl extension. We must check is it (?ismxrg-ismxrg)
           // and change AExtendedSyntax if /x is changed.
           Inc (i, 2); // skip '(?'
           i0 := i;
           while (i <= Len) and (ARegExpr [i] <> ')')
            do Inc (i);
           if i > Len
            then Result := -1 // unbalansed '('
            else
             if TRegExpr.ParseModifiersStr (System.Copy (ARegExpr, i, i - i0), Modif)
              then AExtendedSyntax := (Modif and MaskModX) <> 0;
          end
         else
         begin // subexpression starts
           ASubExprs.Add (''); // just reserve space
           with Stack [StackIdx] do
           begin
             SubExprIdx := ASubExprs.Count - 1;
             StartPos := i;
            end;
           Inc (StackIdx);
          end;
       end;
      ')':
        begin
          if StackIdx = 0 then
            Result := i // unbalanced ')'
          else
          begin
            Dec (StackIdx);
            with Stack [StackIdx] do
            begin
              SubExprLen := i - StartPos + 1;
              ASubExprs.Objects [SubExprIdx] := TObject (StartPos or (SubExprLen shl 16));
              ASubExprs [SubExprIdx] := System.Copy(ARegExpr, StartPos + 1, SubExprLen - 2); // add without brackets
            end;
          end;
        end;
      EscChar: Inc (i); // skip quoted symbol
      '[': begin
        // we have to skip character ranges at once, because they can
        // contain '#', and '#' in it must NOT be recognized as eXtended
        // comment beginning!
        i0 := i;
        Inc (i);
        if ARegExpr [i] = ']' // cannot be 'emty' ranges - this interpretes
         then Inc (i);        // as ']' by itself
        while (i <= Len) and (ARegExpr [i] <> ']') do
         if ARegExpr [i] = EscChar //###0.942
          then Inc (i, 2) // skip 'escaped' char to prevent stopping at '\]'
          else Inc (i);
        if (i > Len) or (ARegExpr [i] <> ']') //###0.942
         then Result := - (i0 + 1); // unbalansed '[' //###0.942
       end;
      '#':
        if AExtendedSyntax then
        begin
          // skip eXtended comments
          while (i <= Len) and (ARegExpr [i] <> #$d) and (ARegExpr [i] <> #$a) do
           // do not use [#$d, #$a] due to UniCode compatibility
            Inc (i);
          while (i + 1 <= Len) and ((ARegExpr [i + 1] = #$d) or (ARegExpr [i + 1] = #$a)) do
            Inc (i); // attempt to work with different kinds of line separators
          // now we are at the line separator that must be skipped.
        end;
      // here is no 'else' clause - we simply skip ordinary chars
     end; // of case
    Inc (i); // skip scanned char
    // ! can move after Len due to skipping quoted symbol
   end;

  // check brackets balance
  if StackIdx <> 0 then
    Result := -1; // unbalansed '('

  // check if entire r.e. added
  if (ASubExprs.Count = 0)
   or ((Integer (ASubExprs.Objects [0]) and $FFFF) <> 1)
   or (((Integer (ASubExprs.Objects [0]) ShR 16) and $FFFF) <> Len)
    // whole r.e. wasn't added because it isn't bracketed
    // well, we add it now:
    then ASubExprs.InsertObject (0, ARegExpr, TObject ((Len shl 16) or 1));

  finally
    FreeMem (Stack);
  end;
end; { of function RegExprSubExpressions
--------------------------------------------------------------}



const
 MAGIC       = TREOp (216);// FProgramm signature

// name            opcode    opnd? meaning
 EEND        = TREOp (0);  // -    End of program
 BOL         = TREOp (1);  // -    Match "" at beginning of line
 EOL         = TREOp (2);  // -    Match "" at end of line
 ANY         = TREOp (3);  // -    Match any one character
 ANYOF       = TREOp (4);  // Str  Match any character in string Str
 ANYBUT      = TREOp (5);  // Str  Match any char. not in string Str
 BRANCH      = TREOp (6);  // Node Match this alternative, or the next
 BACK        = TREOp (7);  // -    Jump backward (Next < 0)
 EXACTLY     = TREOp (8);  // Str  Match string Str
 NOTHING     = TREOp (9);  // -    Match empty string
 STAR        = TREOp (10); // Node Match this (simple) thing 0 or more times
 PLUS        = TREOp (11); // Node Match this (simple) thing 1 or more times
 ANYDIGIT    = TREOp (12); // -    Match any digit (equiv [0-9])
 NOTDIGIT    = TREOp (13); // -    Match not digit (equiv [0-9])
 ANYLETTER   = TREOp (14); // -    Match any letter from property WordChars
 NOTLETTER   = TREOp (15); // -    Match not letter from property WordChars
 ANYSPACE    = TREOp (16); // -    Match any space char (see property SpaceChars)
 NOTSPACE    = TREOp (17); // -    Match not space char (see property SpaceChars)
 BRACES      = TREOp (18); // Node,Min,Max Match this (simple) thing from Min to Max times.
                           //      Min and Max are TREBracesArg
 COMMENT     = TREOp (19); // -    Comment ;)
 EXACTLYCI   = TREOp (20); // Str  Match string Str case insensitive
 ANYOFCI     = TREOp (21); // Str  Match any character in string Str, case insensitive
 ANYBUTCI    = TREOp (22); // Str  Match any char. not in string Str, case insensitive
 LOOPENTRY   = TREOp (23); // Node Start of loop (Node - LOOP for this loop)
 LOOP        = TREOp (24); // Node,Min,Max,LoopEntryJmp - back jump for LOOPENTRY.
                           //      Min and Max are TREBracesArg
                           //      Node - next node in sequence,
                           //      LoopEntryJmp - associated LOOPENTRY node addr
 ANYOFTINYSET= TREOp (25); // Chrs Match any one char from Chrs (exactly TinySetLen chars)
 ANYBUTTINYSET=TREOp (26); // Chrs Match any one char not in Chrs (exactly TinySetLen chars)
 ANYOFFULLSET= TREOp (27); // Set  Match any one char from set of char
                           // - very fast (one CPU instruction !) but takes 32 bytes of p-code
 BSUBEXP     = TREOp (28); // Idx  Match previously matched subexpression #Idx (stored as REChar) //###0.936
 BSUBEXPCI   = TREOp (29); // Idx  -"- in case-insensitive mode

 // Non-Greedy Style Ops //###0.940
 STARNG      = TREOp (30); // Same as START but in non-greedy mode
 PLUSNG      = TREOp (31); // Same as PLUS but in non-greedy mode
 BRACESNG    = TREOp (32); // Same as BRACES but in non-greedy mode
 LOOPNG      = TREOp (33); // Same as LOOP but in non-greedy mode

 // Multiline mode \m
 BOLML       = TREOp (34);  // -    Match "" at beginning of line
 EOLML       = TREOp (35);  // -    Match "" at end of line
 ANYML       = TREOp (36);  // -    Match any one character

 // Word boundary
 BOUND       = TREOp (37);  // Match "" between words //###0.943
 NOTBOUND    = TREOp (38);  // Match "" not between words //###0.943

 // !!! Change OPEN value if you add new opcodes !!!

 OPEN        = TREOp (39); // -    Mark this point in input as start of \n
                           //      OPEN + 1 is \1, etc.
 CLOSE       = TREOp (ord (OPEN) + NSUBEXP);
                           // -    Analogous to OPEN.

 // !!! Don't add new OpCodes after CLOSE !!!

// We work with p-code thru pointers, compatible with PRegExprChar.
// Note: all code components (TRENextOff, TREOp, TREBracesArg, etc)
// must have lengths that can be divided by SizeOf (REChar) !
// A node is TREOp of opcode followed Next "pointer" of TRENextOff type.
// The Next is a offset from the opcode of the node containing it.
// An operand, if any, simply follows the node. (Note that much of
// the code generation knows about this implicit relationship!)
// Using TRENextOff=Integer speed up p-code processing.

// Opcodes description:
//
// BRANCH The set of branches constituting a single choice are hooked
//      together with their "next" pointers, since precedence prevents
//      anything being concatenated to any individual branch.  The
//      "next" pointer of the last BRANCH in a choice points to the
//      thing following the whole choice.  This is also where the
//      final "next" pointer of each individual branch points; each
//      branch starts with the operand node of a BRANCH node.
// BACK Normal "next" pointers all implicitly point forward; BACK
//      exists to make loop structures possible.
// STAR,PLUS,BRACES '?', and complex '*' and '+', are implemented as
//      circular BRANCH structures using BACK. Complex '{min,max}'
//      - as pair LOOPENTRY-LOOP (see below). Simple cases (one
//      character per match) are implemented with STAR, PLUS and
//      BRACES for speed and to minimize recursive plunges.
// LOOPENTRY,LOOP {min,max} are implemented as special pair
//      LOOPENTRY-LOOP. Each LOOPENTRY initialize loopstack for
//      current level.
// OPEN,CLOSE are numbered at compile time.


{=============================================================}
{================== Error handling section ===================}
{=============================================================}

const
 reeOk = 0;
 reeCompNullArgument = 100;
 reeCompRegexpTooBig = 101;
 reeCompParseRegTooManyBrackets = 102;
 reeCompParseRegUnmatchedBrackets = 103;
 reeCompParseRegUnmatchedBrackets2 = 104;
 reeCompParseRegJunkOnEnd = 105;
 reePlusStarOperandCouldBeEmpty = 106;
 reeNestedSQP = 107;
 reeBadHexDigit = 108;
 reeInvalidRange = 109;
 reeParseAtomTrailingBackSlash = 110;
 reeNoHexCodeAfterBSlashX = 111;
 reeHexCodeAfterBSlashXTooBig = 112;
 reeUnmatchedSqBrackets = 113;
 reeInternalUrp = 114;
 reeQPSBFollowsNothing = 115;
 reeTrailingBackSlash = 116;
 reeRarseAtomInternalDisaster = 119;
 reeBRACESArgTooBig = 122;
 reeBracesMinParamGreaterMax = 124;
 reeUnclosedComment = 125;
 reeComplexBracesNotImplemented = 126;
 reeUrecognizedModifier = 127;
 reeBadLinePairedSeparator = 128;
 reeRegRepeatCalledInappropriately = 1000;
 reeMatchPrimMemoryCorruption = 1001;
 reeMatchPrimCorruptedPointers = 1002;
 reeNoExpression = 1003;
 reeCorruptedProgram = 1004;
 reeNoInpitStringSpecified = 1005;
 reeOffsetMustBeGreaterThen0 = 1006;
 reeExecNextWithoutExec = 1007;
 reeGetInputStringWithoutInputString = 1008;
 reeDumpCorruptedOpcode = 1011;
 reeModifierUnsupported = 1013;
 reeLoopStackExceeded = 1014;
 reeLoopWithoutEntry = 1015;
 reeBadPCodeImported = 2000;

function TRegExpr.ErrorMsg (AErrorID : Integer) : RegExprString;
 begin
  case AErrorID of
    reeOk: Result := 'No errors';
    reeCompNullArgument: Result := 'TRegExpr(comp): Null Argument';
    reeCompRegexpTooBig: Result := 'TRegExpr(comp): Regexp Too Big';
    reeCompParseRegTooManyBrackets: Result := 'TRegExpr(comp): ParseReg Too Many ()';
    reeCompParseRegUnmatchedBrackets: Result := 'TRegExpr(comp): ParseReg Unmatched ()';
    reeCompParseRegUnmatchedBrackets2: Result := 'TRegExpr(comp): ParseReg Unmatched ()';
    reeCompParseRegJunkOnEnd: Result := 'TRegExpr(comp): ParseReg Junk On End';
    reePlusStarOperandCouldBeEmpty: Result := 'TRegExpr(comp): *+ Operand Could Be Empty';
    reeNestedSQP: Result := 'TRegExpr(comp): Nested *?+';
    reeBadHexDigit: Result := 'TRegExpr(comp): Bad Hex Digit';
    reeInvalidRange: Result := 'TRegExpr(comp): Invalid [] Range';
    reeParseAtomTrailingBackSlash: Result := 'TRegExpr(comp): Parse Atom Trailing \';
    reeNoHexCodeAfterBSlashX: Result := 'TRegExpr(comp): No Hex Code After \x';
    reeHexCodeAfterBSlashXTooBig: Result := 'TRegExpr(comp): Hex Code After \x Is Too Big';
    reeUnmatchedSqBrackets: Result := 'TRegExpr(comp): Unmatched []';
    reeInternalUrp: Result := 'TRegExpr(comp): Internal Urp';
    reeQPSBFollowsNothing: Result := 'TRegExpr(comp): ?+*{ Follows Nothing';
    reeTrailingBackSlash: Result := 'TRegExpr(comp): Trailing \';
    reeRarseAtomInternalDisaster: Result := 'TRegExpr(comp): RarseAtom Internal Disaster';
    reeBRACESArgTooBig: Result := 'TRegExpr(comp): BRACES Argument Too Big';
    reeBracesMinParamGreaterMax: Result := 'TRegExpr(comp): BRACE Min Param Greater then Max';
    reeUnclosedComment: Result := 'TRegExpr(comp): Unclosed (?#Comment)';
    reeComplexBracesNotImplemented: Result := 'TRegExpr(comp): If you want take part in beta-testing BRACES ''{min,max}'' and non-greedy ops ''*?'', ''+?'', ''??'' for complex cases - remove ''.'' from {.$DEFINE ComplexBraces}';
    reeUrecognizedModifier: Result := 'TRegExpr(comp): Urecognized Modifier';
    reeBadLinePairedSeparator: Result := 'TRegExpr(comp): LinePairedSeparator must countain two different chars or no chars at all';

    reeRegRepeatCalledInappropriately: Result := 'TRegExpr(exec): RegRepeat Called Inappropriately';
    reeMatchPrimMemoryCorruption: Result := 'TRegExpr(exec): MatchPrim Memory Corruption';
    reeMatchPrimCorruptedPointers: Result := 'TRegExpr(exec): MatchPrim Corrupted Pointers';
    reeNoExpression: Result := 'TRegExpr(exec): Not Assigned Expression Property';
    reeCorruptedProgram: Result := 'TRegExpr(exec): Corrupted Program';
    reeNoInpitStringSpecified: Result := 'TRegExpr(exec): No Input String Specified';
    reeOffsetMustBeGreaterThen0: Result := 'TRegExpr(exec): Offset Must Be Greater Then 0';
    reeExecNextWithoutExec: Result := 'TRegExpr(exec): ExecNext Without Exec[Pos]';
    reeGetInputStringWithoutInputString: Result := 'TRegExpr(exec): GetInputString Without InputString';
    reeDumpCorruptedOpcode: Result := 'TRegExpr(dump): Corrupted Opcode';
    reeLoopStackExceeded: Result := 'TRegExpr(exec): Loop Stack Exceeded';
    reeLoopWithoutEntry: Result := 'TRegExpr(exec): Loop Without LoopEntry !';

    reeBadPCodeImported: Result := 'TRegExpr(misc): Bad p-code imported';
    else Result := 'Unknown error';
   end;
 end; { of procedure TRegExpr.Error
--------------------------------------------------------------}

function TRegExpr.LastError : Integer;
 begin
  Result := FLastError;
  FLastError := reeOk;
 end; { of function TRegExpr.LastError
--------------------------------------------------------------}


{=============================================================}
{===================== Common section ========================}
{=============================================================}

class function TRegExpr.VersionMajor : Integer; //###0.944
 begin
  Result := TRegExprVersionMajor;
 end; { of class function TRegExpr.VersionMajor
--------------------------------------------------------------}

class function TRegExpr.VersionMinor : Integer; //###0.944
 begin
  Result := TRegExprVersionMinor;
 end; { of class function TRegExpr.VersionMinor
--------------------------------------------------------------}

constructor TRegExpr.Create;
 begin
  inherited;
  FProgramm := nil;
  FExpression := nil;
  FInputString := nil;

  FRegexpbeg := nil;
  FExprIsCompiled := False;

  ModifierI := RegExprModifierI;
  ModifierR := RegExprModifierR;
  ModifierS := RegExprModifierS;
  ModifierG := RegExprModifierG;
  ModifierM := RegExprModifierM; //###0.940

  SpaceChars := RegExprSpaceChars; //###0.927
  WordChars := RegExprWordChars; //###0.929
  FInvertCase := RegExprInvertCaseFunction; //###0.927

  FLineSeparators := RegExprLineSeparators; //###0.941
  LinePairedSeparator := RegExprLinePairedSeparator; //###0.941
 end; { of constructor TRegExpr.Create
--------------------------------------------------------------}

destructor TRegExpr.Destroy;
 begin
  if FProgramm <> nil
   then FreeMem (FProgramm);
  if FExpression <> nil
   then FreeMem (FExpression);
  if FInputString <> nil
   then FreeMem (FInputString);
 end; { of destructor TRegExpr.Destroy
--------------------------------------------------------------}

class function TRegExpr.InvertCaseFunction (const Ch : REChar) : REChar;
 begin
  {$IFDEF SynRegUniCode}
  if Ch >= #128
   then Result := Ch
  else
  {$ENDIF}
   begin
    Result := {$IFDEF FPC}AnsiUpperCase (Ch) [1]{$ELSE} {$IFDEF SYN_WIN32}REChar (CharUpper (PChar (Ch))){$ELSE}REChar (toupper (Integer (Ch))){$ENDIF} {$ENDIF};
    if Result = Ch
     then Result := {$IFDEF FPC}AnsiLowerCase (Ch) [1]{$ELSE} {$IFDEF SYN_WIN32}REChar (CharLower (PChar (Ch))){$ELSE}REChar(tolower (Integer (Ch))){$ENDIF} {$ENDIF};
   end;
 end; { of function TRegExpr.InvertCaseFunction
--------------------------------------------------------------}

function TRegExpr.GetExpression : RegExprString;
 begin
  if FExpression <> nil
   then Result := FExpression
   else Result := '';
 end; { of function TRegExpr.GetExpression
--------------------------------------------------------------}

procedure TRegExpr.SetExpression (const s : RegExprString);
var
  Len : Integer; //###0.950
begin
  if (s <> FExpression) or not FExprIsCompiled then
  begin
    FExprIsCompiled := False;
    if FExpression <> nil then
    begin
      FreeMem (FExpression);
      FExpression := nil;
    end;
    if s <> '' then
    begin
      Len := length (s); //###0.950
      GetMem (FExpression, (Len + 1) * SizeOf (REChar));
//      StrPCopy (FExpression, s); //###0.950 replaced due to StrPCopy limitation of 255 chars
      {$IFDEF SynRegUniCode}
      StrPCopy (FExpression, Copy (s, 1, Len)); //###0.950
      {$ELSE}
      StrLCopy (FExpression, PRegExprChar (s), Len); //###0.950
      {$ENDIF SynRegUniCode}

      InvalidateProgramm; //###0.941
    end;
  end;
end; { of procedure TRegExpr.SetExpression
--------------------------------------------------------------}

function TRegExpr.GetSubExprMatchCount : Integer;
begin
  if Assigned (FInputString) then
  begin
    Result := NSUBEXP - 1;
    while (Result > 0) and ((startp [Result] = nil) or (endp [Result] = nil)) do
      Dec(Result);
  end
  else
    Result := -1;
end; { of function TRegExpr.GetSubExprMatchCount
--------------------------------------------------------------}

function TRegExpr.GetMatchPos (Idx : Integer) : Integer;
begin
  if (Idx >= 0) and (Idx < NSUBEXP) and Assigned (FInputString) and Assigned (startp [Idx]) and Assigned (endp [Idx]) then
    Result := (startp [Idx] - FInputString) + 1
  else
    Result := -1;
end; { of function TRegExpr.GetMatchPos
--------------------------------------------------------------}

function TRegExpr.GetMatchLen (Idx : Integer) : Integer;
begin
  if (Idx >= 0) and (Idx < NSUBEXP) and Assigned (FInputString)
    and Assigned (startp [Idx]) and Assigned (endp [Idx]) then
    Result := endp [Idx] - startp [Idx]
  else
    Result := -1;
end; { of function TRegExpr.GetMatchLen
--------------------------------------------------------------}

function TRegExpr.GetMatch (Idx : Integer) : RegExprString;
begin
  if (Idx >= 0) and (Idx < NSUBEXP) and Assigned(FInputString) and Assigned(startp [Idx]) and Assigned(endp [Idx]) then
     SetString (Result, startp [idx], endp [idx] - startp [idx])
   else
     Result := '';
end; { of function TRegExpr.GetMatch
--------------------------------------------------------------}

function TRegExpr.GetModifierStr : RegExprString;
begin
  Result := '-';

  if ModifierI
   then Result := 'i' + Result
   else Result := Result + 'i';
  if ModifierR
   then Result := 'r' + Result
   else Result := Result + 'r';
  if ModifierS
   then Result := 's' + Result
   else Result := Result + 's';
  if ModifierG
   then Result := 'g' + Result
   else Result := Result + 'g';
  if ModifierM
   then Result := 'm' + Result
   else Result := Result + 'm';
  if ModifierX
   then Result := 'x' + Result
   else Result := Result + 'x';

  if Result [length (Result)] = '-' // remove '-' if all modifiers are 'On'
   then System.Delete (Result, length (Result), 1);
end; { of function TRegExpr.GetModifierStr
--------------------------------------------------------------}

class function TRegExpr.ParseModifiersStr(const AModifiers: RegExprString;
  var AModifiersInt: Integer) : Boolean;
// !!! Be carefull - this is class function and must not use object instance fields
var
  i : Integer;
  IsOn : Boolean;
  Mask : Integer;
begin
  Result := True;
  IsOn := True;
  {$IFNDEF SYN_COMPILER_24_UP}
  Mask := 0; // prevent compiler warning
  {$ENDIF}
  for i := 1 to Length(AModifiers) do
   if AModifiers [i] = '-'
    then IsOn := False
    else
    begin
      if Pos (AModifiers [i], 'iI') > 0 then
        Mask := MaskModI
      else
      if Pos (AModifiers [i], 'rR') > 0 then
        Mask := MaskModR
      else
      if Pos (AModifiers [i], 'sS') > 0 then
        Mask := MaskModS
      else
      if Pos (AModifiers [i], 'gG') > 0 then
        Mask := MaskModG
      else
      if Pos (AModifiers [i], 'mM') > 0 then
        Mask := MaskModM
      else
      if Pos (AModifiers [i], 'xX') > 0 then
        Mask := MaskModX
      else
      begin
        Result := False;
        Exit;
      end;
      if IsOn then
        AModifiersInt := AModifiersInt or Mask
      else
        AModifiersInt := AModifiersInt and not Mask;
    end;
end; { of function TRegExpr.ParseModifiersStr
--------------------------------------------------------------}

procedure TRegExpr.SetModifierStr (const AModifiers : RegExprString);
begin
  if not ParseModifiersStr (AModifiers, FModifiers) then
    Error (reeModifierUnsupported);
end; { of procedure TRegExpr.SetModifierStr
--------------------------------------------------------------}

function TRegExpr.GetModifier (AIndex : Integer) : Boolean;
var
  Mask: Integer;
begin
  Result := False;
  case AIndex of
    1: Mask := MaskModI;
    2: Mask := MaskModR;
    3: Mask := MaskModS;
    4: Mask := MaskModG;
    5: Mask := MaskModM;
    6: Mask := MaskModX;
    else
      begin
        Error (reeModifierUnsupported);
        Exit;
      end;
  end;
  Result := (FModifiers and Mask) <> 0;
end; { of function TRegExpr.GetModifier
--------------------------------------------------------------}

procedure TRegExpr.SetModifier (AIndex : Integer; ASet : Boolean);
var
  Mask: Integer;
begin
  case AIndex of
    1: Mask := MaskModI;
    2: Mask := MaskModR;
    3: Mask := MaskModS;
    4: Mask := MaskModG;
    5: Mask := MaskModM;
    6: Mask := MaskModX;
    else
      begin
        Error (reeModifierUnsupported);
        Exit;
      end;
  end;
  if ASet then
    FModifiers := FModifiers or Mask
  else
    FModifiers := FModifiers and not Mask;
end; { of procedure TRegExpr.SetModifier
--------------------------------------------------------------}


{=============================================================}
{==================== Compiler section =======================}
{=============================================================}

procedure TRegExpr.InvalidateProgramm;
begin
  if FProgramm <> nil then
  begin
    FreeMem (FProgramm);
    FProgramm := nil;
  end;
end; { of procedure TRegExpr.InvalidateProgramm
--------------------------------------------------------------}

procedure TRegExpr.Compile; //###0.941
begin
  if FExpression = nil then
  begin // No Expression assigned
    Error (reeNoExpression);
    Exit;
  end;
  CompileRegExpr (FExpression);
end; { of procedure TRegExpr.Compile
--------------------------------------------------------------}

function TRegExpr.IsProgrammOk : Boolean;
{$IFNDEF SynRegUniCode}
var
  i : Integer;
{$ENDIF}
begin
  Result := False;

  // check modifiers
  if FModifiers <> FProgModifiers //###0.941
   then InvalidateProgramm;

  // can we optimize line separators by using sets?
  {$IFNDEF SynRegUniCode}
  FLineSeparatorsSet := [];
  for i := 1 to length (FLineSeparators)
   do System.Include (FLineSeparatorsSet, FLineSeparators [i]);
  {$ENDIF}

  // [Re]compile if needed
  if FProgramm = nil
   then Compile; //###0.941

  // check [re]compiled FProgramm
  if FProgramm = nil
   then Exit // error was set/raised by Compile (was reeExecAfterCompErr)
  else if FProgramm [0] <> MAGIC // Program corrupted.
   then Error (reeCorruptedProgram)
  else Result := True;
end; { of function TRegExpr.IsProgrammOk
--------------------------------------------------------------}

procedure TRegExpr.Tail (p : PRegExprChar; val : PRegExprChar);
// set the next-pointer at the end of a node chain
 var
  scan : PRegExprChar;
  temp : PRegExprChar;
//  i : int64;
 begin
  if p = @FRegdummy
   then Exit;
  // Find last node.
  scan := p;
  repeat
   temp := regnext (scan);
   if temp = nil
    then Break;
   scan := temp;
  until False;
  // Set Next 'pointer'
  if val < scan
   then PRENextOff (scan + REOpSz)^ := - (scan - val) //###0.948
   // work around PWideChar subtraction bug (Delphi uses
   // shr after subtraction to calculate widechar distance %-( )
   // so, if difference is negative we have .. the "feature" :(
   // I could wrap it in $IFDEF UniCode, but I didn't because
   // "P � Q computes the difference between the address given
   // by P (the higher address) and the address given by Q (the
   // lower address)" - Delphi help quotation.
   else PRENextOff (scan + REOpSz)^ := val - scan; //###0.933
 end; { of procedure TRegExpr.Tail
--------------------------------------------------------------}

procedure TRegExpr.OpTail (p : PRegExprChar; val : PRegExprChar);
// regtail on operand of first argument; nop if operandless
 begin
  // "Operandless" and "op != BRANCH" are synonymous in practice.
  if (p = nil) or (p = @FRegdummy) or (PREOp (p)^ <> BRANCH)
   then Exit;
  Tail (p + REOpSz + RENextOffSz, val); //###0.933
 end; { of procedure TRegExpr.OpTail
--------------------------------------------------------------}

function TRegExpr.EmitNode (op : TREOp) : PRegExprChar; //###0.933
// emit a node, return location
begin
  Result := FRegcode;
  if Result <> @FRegdummy then
  begin
     PREOp (FRegcode)^ := op;
     Inc (FRegcode, REOpSz);
     PRENextOff (FRegcode)^ := 0; // Next "pointer" := nil
     Inc (FRegcode, RENextOffSz);
  end
  else
    Inc (FRegsize, REOpSz + RENextOffSz); // compute code size without code generation
end; { of function TRegExpr.EmitNode
--------------------------------------------------------------}

procedure TRegExpr.EmitC (b : REChar);
// emit a byte to code
begin
  if FRegcode <> @FRegdummy then
  begin
    FRegcode^ := b;
    Inc (FRegcode);
  end
  else
    Inc (FRegsize); // Type of p-code pointer always is ^REChar
end; { of procedure TRegExpr.EmitC
--------------------------------------------------------------}

procedure TRegExpr.InsertOperator (op : TREOp; opnd : PRegExprChar; sz : Integer);
// insert an operator in front of already-emitted operand
// Means relocating the operand.
var
  src, dst, place : PRegExprChar;
  i : Integer;
begin
  if FRegcode = @FRegdummy then
  begin
    Inc (FRegsize, sz);
    Exit;
  end;
  src := FRegcode;
  Inc (FRegcode, sz);
  dst := FRegcode;
  while src > opnd do
  begin
    Dec (dst);
    Dec (src);
    dst^ := src^;
  end;
  place := opnd; // Op node, where operand used to be.
  PREOp (place)^ := op;
  Inc (place, REOpSz);
  for i := 1 + REOpSz to sz do
  begin
    place^ := #0;
    Inc (place);
  end;
end; { of procedure TRegExpr.InsertOperator
--------------------------------------------------------------}

function strcspn (s1 : PRegExprChar; s2 : PRegExprChar) : Integer;
// find length of initial segment of s1 consisting
// entirely of characters not from s2
 var scan1, scan2 : PRegExprChar;
 begin
  Result := 0;
  scan1 := s1;
  while scan1^ <> #0 do
  begin
    scan2 := s2;
    while scan2^ <> #0 do
     if scan1^ = scan2^
      then Exit
      else Inc (scan2);
    Inc (Result);
    Inc (scan1)
   end;
 end; { of function strcspn
--------------------------------------------------------------}

const
// Flags to be passed up and down.
 HASWIDTH =   01; // Known never to match nil string.
 SIMPLE   =   02; // Simple enough to be STAR/PLUS/BRACES operand.
 SPSTART  =   04; // Starts with * or +.
 WORST    =   0;  // Worst case.
 META : array [0 .. 12] of REChar = (
  '^', '$', '.', '[', '(', ')', '|', '?', '+', '*', EscChar, '{', #0);
 // Any modification must be synchronized with QuoteRegExprMetaChars !!!

{$IFDEF SynRegUniCode}
 RusRangeLo : array [0 .. 33] of REChar =
  (#$430,#$431,#$432,#$433,#$434,#$435,#$451,#$436,#$437,
   #$438,#$439,#$43A,#$43B,#$43C,#$43D,#$43E,#$43F,
   #$440,#$441,#$442,#$443,#$444,#$445,#$446,#$447,
   #$448,#$449,#$44A,#$44B,#$44C,#$44D,#$44E,#$44F,#0);
 RusRangeHi : array [0 .. 33] of REChar =
  (#$410,#$411,#$412,#$413,#$414,#$415,#$401,#$416,#$417,
   #$418,#$419,#$41A,#$41B,#$41C,#$41D,#$41E,#$41F,
   #$420,#$421,#$422,#$423,#$424,#$425,#$426,#$427,
   #$428,#$429,#$42A,#$42B,#$42C,#$42D,#$42E,#$42F,#0);
 RusRangeLoLow = #$430{'�'};
 RusRangeLoHigh = #$44F{'�'};
 RusRangeHiLow = #$410{'�'};
 RusRangeHiHigh = #$42F{'�'};
{$ELSE}
 RusRangeLo = '��������������������������������';
 RusRangeHi = '�����Ũ��������������������������';
 RusRangeLoLow = '�';
 RusRangeLoHigh = '�';
 RusRangeHiLow = '�';
 RusRangeHiHigh = '�';
{$ENDIF}

function TRegExpr.CompileRegExpr (exp : PRegExprChar) : Boolean;
// compile a regular expression into internal code
// We can't allocate space until we know how big the compiled form will be,
// but we can't compile it (and thus know how big it is) until we've got a
// place to put the code.  So we cheat:  we compile it twice, once with code
// generation turned off and size counting turned on, and once "for real".
// This also means that we don't allocate space until we are sure that the
// thing really will compile successfully, and we never have to move the
// code and thus invalidate pointers into it.  (Note that it has to be in
// one piece because free() must be able to free it all.)
// Beware that the optimization-preparation code in here knows about some
// of the structure of the compiled regexp.
 var
  scan, longest : PRegExprChar;
  len : cardinal;
  flags : Integer;
 begin
  Result := False; // life too dark

  FRegParse := nil; // for correct error handling
  FRegexpbeg := exp;
  try

  if FProgramm <> nil then
  begin
    FreeMem (FProgramm);
    FProgramm := nil;
  end;

  if exp = nil then
  begin
    Error (reeCompNullArgument);
    Exit;
  end;

  FProgModifiers := FModifiers;
  // well, may it's paranoia. I'll check it later... !!!!!!!!

  // First pass: determine size, legality.
  FCompModifiers := FModifiers;
  FRegParse := exp;
  FRegnpar := 1;
  FRegsize := 0;
  FRegcode := @FRegdummy;
  EmitC (MAGIC);
  if ParseReg (0, flags) = nil
   then Exit;

  // Small enough for 2-bytes FProgramm pointers ?
  // ###0.933 no real p-code length limits now :)))
//  if FRegsize >= 64 * 1024 then
//  begin
//    Error (reeCompRegexpTooBig);
//    Exit;
//  end;

  // Allocate space.
  GetMem (FProgramm, FRegsize * SizeOf (REChar));

  // Second pass: emit code.
  FCompModifiers := FModifiers;
  FRegParse := exp;
  FRegnpar := 1;
  FRegcode := FProgramm;
  EmitC (MAGIC);
  if ParseReg (0, flags) = nil
   then Exit;

  // Dig out information for optimizations.
  {$IFDEF UseFirstCharSet} //###0.929
  FFirstCharSet := [];
  FillFirstCharSet (FProgramm + REOpSz);
  {$ENDIF}
  regstart := #0; // Worst-case defaults.
  reganch := #0;
  regmust := nil;
  regmlen := 0;
  scan := FProgramm + REOpSz; // First BRANCH.
  if PREOp (regnext (scan))^ = EEND then
  begin // Only one top-level choice.
    scan := scan + REOpSz + RENextOffSz;

    // Starting-point info.
    if PREOp (scan)^ = EXACTLY
     then regstart := (scan + REOpSz + RENextOffSz)^
     else if PREOp (scan)^ = BOL
           then Inc (reganch);

    // If there's something expensive in the r.e., find the longest
    // literal string that must appear and make it the regmust.  Resolve
    // ties in favor of later strings, since the regstart check works
    // with the beginning of the r.e. and avoiding duplication
    // strengthens checking.  Not a strong reason, but sufficient in the
    // absence of others.
    if (flags and SPSTART) <> 0 then
    begin
      longest := nil;
      len := 0;
      while scan <> nil do
      begin
        if (PREOp (scan)^ = EXACTLY)
           and (strlen (scan + REOpSz + RENextOffSz) >= len) then
           begin
            longest := scan + REOpSz + RENextOffSz;
            len := strlen (longest);
         end;
        scan := regnext (scan);
      end;
      regmust := longest;
      regmlen := len;
    end;
  end;

  Result := True;

  finally
    if not Result then
      InvalidateProgramm;
    FRegexpbeg := nil;
    FExprIsCompiled := Result; //###0.944
  end;

end; { of function TRegExpr.CompileRegExpr
--------------------------------------------------------------}

function TRegExpr.ParseReg (paren : Integer; var flagp : Integer) : PRegExprChar;
// regular expression, i.e. main body or parenthesized thing
// Caller must absorb opening parenthesis.
// Combining parenthesis handling with the base level of regular expression
// is a trifle forced, but the need to tie the tails of the branches to what
// follows makes it hard to avoid.
var
  ret, br, ender : PRegExprChar;
  parno : Integer;
  flags : Integer;
  SavedModifiers : Integer;
begin
  Result := nil;
  flagp := HASWIDTH; // Tentatively.
  parno := 0; // eliminate compiler stupid warning
  SavedModifiers := FCompModifiers;

  // Make an OPEN node, if parenthesized.
  if paren <> 0 then
  begin
    if FRegnpar >= NSUBEXP then
    begin
      Error (reeCompParseRegTooManyBrackets);
      Exit;
    end;
    parno := FRegnpar;
    Inc (FRegnpar);
    ret := EmitNode (TREOp (ord (OPEN) + parno));
  end
  else
    ret := nil;

  // Pick up the branches, linking them together.
  br := ParseBranch (flags);
  if br = nil then
  begin
    Result := nil;
    Exit;
  end;
  if ret <> nil then
    Tail (ret, br) // OPEN -> first.
  else
    ret := br;
  if (flags and HASWIDTH) = 0 then
    flagp := flagp and not HASWIDTH;
  flagp := flagp or flags and SPSTART;
  while (FRegParse^ = '|') do
  begin
    Inc (FRegParse);
    br := ParseBranch (flags);
    if br = nil then
    begin
      Result := nil;
      Exit;
    end;
    Tail (ret, br); // BRANCH -> BRANCH.
    if (flags and HASWIDTH) = 0
     then flagp := flagp and not HASWIDTH;
    flagp := flagp or flags and SPSTART;
   end;

  // Make a closing node, and hook it on the end.
  if paren <> 0
   then ender := EmitNode (TREOp (ord (CLOSE) + parno))
   else ender := EmitNode (EEND);
  Tail (ret, ender);

  // Hook the tails of the branches to the closing node.
  br := ret;
  while br <> nil do
  begin
    OpTail (br, ender);
    br := regnext (br);
   end;

  // Check for proper termination.
  if paren <> 0 then
   if FRegParse^ <> ')' then
   begin
      Error (reeCompParseRegUnmatchedBrackets);
      Exit;
   end
   else
     Inc (FRegParse); // skip trailing ')'
  if (paren = 0) and (FRegParse^ <> #0) then
  begin
    if FRegParse^ = ')' then
      Error (reeCompParseRegUnmatchedBrackets2)
    else
      Error (reeCompParseRegJunkOnEnd);
    Exit;
  end;
  FCompModifiers := SavedModifiers; // restore modifiers of parent
  Result := ret;
 end; { of function TRegExpr.ParseReg
--------------------------------------------------------------}

function TRegExpr.ParseBranch (var flagp : Integer) : PRegExprChar;
// one alternative of an | operator
// Implements the concatenation operator.
var
  ret, chain, latest : PRegExprChar;
  flags : Integer;
begin
  flagp := WORST; // Tentatively.

  ret := EmitNode (BRANCH);
  chain := nil;
  while (FRegParse^ <> #0) and (FRegParse^ <> '|') and (FRegParse^ <> ')') do
  begin
    latest := ParsePiece (flags);
    if latest = nil then
    begin
      Result := nil;
      Exit;
    end;
    flagp := flagp or flags and HASWIDTH;
    if chain = nil then // First piece.
      flagp := flagp or flags and SPSTART
    else
      Tail(chain, latest);
    chain := latest;
  end;
  if chain = nil then // Loop ran zero times.
    EmitNode (NOTHING);
  Result := ret;
end; { of function TRegExpr.ParseBranch
--------------------------------------------------------------}

function TRegExpr.ParsePiece (var flagp : Integer) : PRegExprChar;
// something followed by possible [*+?{]
// Note that the branching code sequences used for ? and the general cases
// of * and + and { are somewhat optimized:  they use the same NOTHING node as
// both the endmarker for their branch list and the body of the last branch.
// It might seem that this node could be dispensed with entirely, but the
// endmarker role is not redundant.
 function parsenum (AStart, AEnd : PRegExprChar) : TREBracesArg;
  begin
   Result := 0;
   if AEnd - AStart + 1 > 8 then
   begin // prevent stupid scanning
     Error (reeBRACESArgTooBig);
     Exit;
   end;
   while AStart <= AEnd do
   begin
     Result := Result * 10 + (ord (AStart^) - ord ('0'));
     Inc (AStart);
   end;
   if (Result > MaxBracesArg) or (Result < 0) then
   begin
     Error (reeBRACESArgTooBig);
     Exit;
    end;
  end;

 var
  op : REChar;
  NonGreedyOp, NonGreedyCh : Boolean; //###0.940
  TheOp : TREOp; //###0.940
  NextNode : PRegExprChar;
  flags : Integer;
  BracesMin, Bracesmax : TREBracesArg;
  p, savedparse : PRegExprChar;

procedure EmitComplexBraces (ABracesMin, ABracesMax : TREBracesArg;
  ANonGreedyOp : Boolean); //###0.940
  {$IFDEF ComplexBraces}
var
   off : Integer;
  {$ENDIF}
   begin
   {$IFNDEF ComplexBraces}
   Error (reeComplexBracesNotImplemented);
   {$ELSE}
   if ANonGreedyOp
    then TheOp := LOOPNG
    else TheOp := LOOP;
   InsertOperator (LOOPENTRY, Result, REOpSz + RENextOffSz);
   NextNode := EmitNode (TheOp);
   if FRegcode <> @FRegdummy then
   begin
     off := (Result + REOpSz + RENextOffSz) - (FRegcode - REOpSz - RENextOffSz); // back to Atom after LOOPENTRY
     PREBracesArg (FRegcode)^ := ABracesMin;
     Inc (FRegcode, REBracesArgSz);
     PREBracesArg (FRegcode)^ := ABracesMax;
     Inc (FRegcode, REBracesArgSz);
     PRENextOff (FRegcode)^ := off;
     Inc (FRegcode, RENextOffSz);
   end
   else
     Inc (FRegsize, REBracesArgSz * 2 + RENextOffSz);
   Tail (Result, NextNode); // LOOPENTRY -> LOOP
   if FRegcode <> @FRegdummy then
    Tail (Result + REOpSz + RENextOffSz, NextNode); // Atom -> LOOP
   {$ENDIF}
  end;

 procedure EmitSimpleBraces (ABracesMin, ABracesMax : TREBracesArg;
   ANonGreedyOp : Boolean); //###0.940
  begin
   if ANonGreedyOp //###0.940
    then TheOp := BRACESNG
    else TheOp := BRACES;
   InsertOperator (TheOp, Result, REOpSz + RENextOffSz + REBracesArgSz * 2);
   if FRegcode <> @FRegdummy then begin
     PREBracesArg (Result + REOpSz + RENextOffSz)^ := ABracesMin;
     PREBracesArg (Result + REOpSz + RENextOffSz + REBracesArgSz)^ := ABracesMax;
    end;
  end;

 begin
  Result := ParseAtom (flags);
  if Result = nil
   then Exit;

  op := FRegParse^;
  if not ((op = '*') or (op = '+') or (op = '?') or (op = '{')) then begin
    flagp := flags;
    Exit;
   end;
  if ((flags and HASWIDTH) = 0) and (op <> '?') then begin
    Error (reePlusStarOperandCouldBeEmpty);
    Exit;
   end;

  case op of
    '*': begin
      flagp := WORST or SPSTART;
      NonGreedyCh := (FRegParse + 1)^ = '?'; //###0.940
      NonGreedyOp := NonGreedyCh or ((FCompModifiers and MaskModG) = 0); //###0.940
      if (flags and SIMPLE) = 0 then begin
         if NonGreedyOp //###0.940
          then EmitComplexBraces (0, MaxBracesArg, NonGreedyOp)
          else
          begin // Emit x* as (x&|), where & means "self".
            InsertOperator (BRANCH, Result, REOpSz + RENextOffSz); // Either x
            OpTail (Result, EmitNode (BACK)); // and loop
            OpTail (Result, Result); // back
            Tail (Result, EmitNode (BRANCH)); // or
            Tail (Result, EmitNode (NOTHING)); // nil.
          end
        end
       else
       begin // Simple
         if NonGreedyOp //###0.940
          then TheOp := STARNG
          else TheOp := STAR;
         InsertOperator (TheOp, Result, REOpSz + RENextOffSz);
       end;
      if NonGreedyCh //###0.940
       then Inc (FRegParse); // Skip extra char ('?')
     end; { of case '*'}
    '+': begin
      flagp := WORST or SPSTART or HASWIDTH;
      NonGreedyCh := (FRegParse + 1)^ = '?'; //###0.940
      NonGreedyOp := NonGreedyCh or ((FCompModifiers and MaskModG) = 0); //###0.940
      if (flags and SIMPLE) = 0 then begin
         if NonGreedyOp //###0.940
          then EmitComplexBraces (1, MaxBracesArg, NonGreedyOp)
          else
          begin // Emit x+ as x(&|), where & means "self".
            NextNode := EmitNode (BRANCH); // Either
            Tail (Result, NextNode);
            Tail (EmitNode (BACK), Result);    // loop back
            Tail (NextNode, EmitNode (BRANCH)); // or
            Tail (Result, EmitNode (NOTHING)); // nil.
           end
        end
       else
       begin // Simple
         if NonGreedyOp //###0.940
          then TheOp := PLUSNG
          else TheOp := PLUS;
         InsertOperator (TheOp, Result, REOpSz + RENextOffSz);
        end;
      if NonGreedyCh //###0.940
       then Inc (FRegParse); // Skip extra char ('?')
     end; { of case '+'}
    '?': begin
      flagp := WORST;
      NonGreedyCh := (FRegParse + 1)^ = '?'; //###0.940
      NonGreedyOp := NonGreedyCh or ((FCompModifiers and MaskModG) = 0); //###0.940
      if NonGreedyOp then begin //###0.940  // We emit x?? as x{0,1}?
         if (flags and SIMPLE) = 0
          then EmitComplexBraces (0, 1, NonGreedyOp)
          else EmitSimpleBraces (0, 1, NonGreedyOp);
        end
       else
       begin // greedy '?'
         InsertOperator (BRANCH, Result, REOpSz + RENextOffSz); // Either x
         Tail (Result, EmitNode (BRANCH));  // or
         NextNode := EmitNode (NOTHING); // nil.
         Tail (Result, NextNode);
         OpTail (Result, NextNode);
        end;
      if NonGreedyCh //###0.940
       then Inc (FRegParse); // Skip extra char ('?')
     end; { of case '?'}
   '{': begin
      savedparse := FRegParse;
      // !!!!!!!!!!!!
      // Filip Jirsak's note - what will happen, when we are at the end of regparse?
      Inc (FRegParse);
      p := FRegParse;
      while Pos (FRegParse^, '0123456789') > 0  // <min> MUST appear
       do Inc (FRegParse);
      if (FRegParse^ <> '}') and (FRegParse^ <> ',') or (p = FRegParse) then begin
        FRegParse := savedparse;
        flagp := flags;
        Exit;
       end;
      BracesMin := parsenum (p, FRegParse - 1);
      if FRegParse^ = ',' then begin
         Inc (FRegParse);
         p := FRegParse;
         while Pos (FRegParse^, '0123456789') > 0
          do Inc (FRegParse);
         if FRegParse^ <> '}' then begin
           FRegParse := savedparse;
           Exit;
          end;
         if p = FRegParse
          then BracesMax := MaxBracesArg
          else BracesMax := parsenum (p, FRegParse - 1);
        end
       else BracesMax := BracesMin; // {n} == {n,n}
      if BracesMin > BracesMax then begin
        Error (reeBracesMinParamGreaterMax);
        Exit;
       end;
      if BracesMin > 0
       then flagp := WORST;
      if BracesMax > 0
       then flagp := flagp or HASWIDTH or SPSTART;

      NonGreedyCh := (FRegParse + 1)^ = '?'; //###0.940
      NonGreedyOp := NonGreedyCh or ((FCompModifiers and MaskModG) = 0); //###0.940
      if (flags and SIMPLE) <> 0
       then EmitSimpleBraces (BracesMin, BracesMax, NonGreedyOp)
       else EmitComplexBraces (BracesMin, BracesMax, NonGreedyOp);
      if NonGreedyCh //###0.940
       then Inc (FRegParse); // Skip extra char '?'
     end; { of case '{'}
//    else // here we can't be
   end; { of case op}

  Inc (FRegParse);
  if (FRegParse^ = '*') or (FRegParse^ = '+') or (FRegParse^ = '?') or (FRegParse^ = '{') then begin
    Error (reeNestedSQP);
    Exit;
   end;
 end; { of function TRegExpr.ParsePiece
--------------------------------------------------------------}

function TRegExpr.ParseAtom (var flagp : Integer) : PRegExprChar;
// the lowest level
// Optimization:  gobbles an entire sequence of ordinary characters so that
// it can turn them into a single node, which is smaller to store and
// faster to run.  Backslashed characters are exceptions, each becoming a
// separate node; the code is simpler that way and it's not worth fixing.
 var
  ret : PRegExprChar;
  flags : Integer;
  RangeBeg, RangeEnd : REChar;
  CanBeRange : Boolean;
  len : Integer;
  ender : REChar;
  begmodfs : PRegExprChar;

  {$IFDEF UseSetOfChar} //###0.930
  RangePCodeBeg : PRegExprChar;
  RangePCodeIdx : Integer;
  RangeIsCI : Boolean;
  RangeSet : TSetOfREChar;
  RangeLen : Integer;
  RangeChMin, RangeChMax : REChar;
  {$ENDIF}

 procedure EmitExactly (ch : REChar);
  begin
   if (FCompModifiers and MaskModI) <> 0
    then ret := EmitNode (EXACTLYCI)
    else ret := EmitNode (EXACTLY);
   EmitC (ch);
   EmitC (#0);
   flagp := flagp or HASWIDTH or SIMPLE;
  end;

 procedure EmitStr (const s : RegExprString);
  var i : Integer;
  begin
   for i := 1 to length (s)
    do EmitC (s [i]);
  end;

 function HexDig (ch : REChar) : Integer;
  begin
   Result := 0;
   if (ch >= 'a') and (ch <= 'f')
    then ch := REChar (ord (ch) - (ord ('a') - ord ('A')));
   if (ch < '0') or (ch > 'F') or ((ch > '9') and (ch < 'A')) then begin
     Error (reeBadHexDigit);
     Exit;
    end;
   Result := ord (ch) - ord ('0');
   if ch >= 'A'
    then Result := Result - (ord ('A') - ord ('9') - 1);
  end;

 function EmitRange (AOpCode : REChar) : PRegExprChar;
  begin
   {$IFDEF UseSetOfChar}
   case AOpCode of
     ANYBUTCI, ANYBUT:
       Result := EmitNode (ANYBUTTINYSET);
     else // ANYOFCI, ANYOF
       Result := EmitNode (ANYOFTINYSET);
    end;
   case AOpCode of
     ANYBUTCI, ANYOFCI:
       RangeIsCI := True;
     else // ANYBUT, ANYOF
       RangeIsCI := False;
    end;
   RangePCodeBeg := FRegcode;
   RangePCodeIdx := FRegsize;
   RangeLen := 0;
   RangeSet := [];
   RangeChMin := #255;
   RangeChMax := #0;
   {$ELSE}
   Result := EmitNode (AOpCode);
   // ToDo:
   // !!!!!!!!!!!!! Implement ANYOF[BUT]TINYSET generation for UniCode !!!!!!!!!!
   {$ENDIF}
  end;

{$IFDEF UseSetOfChar}
 procedure EmitRangeCPrim (b : REChar); //###0.930
  begin
   if b in RangeSet
    then Exit;
   Inc (RangeLen);
   if b < RangeChMin
    then RangeChMin := b;
   if b > RangeChMax
    then RangeChMax := b;
   Include (RangeSet, b);
  end;
 {$ENDIF}

 procedure EmitRangeC (b : REChar);
  {$IFDEF UseSetOfChar}
  var
   Ch : REChar;
  {$ENDIF}
  begin
   CanBeRange := False;
   {$IFDEF UseSetOfChar}
    if b <> #0 then begin
       EmitRangeCPrim (b); //###0.930
       if RangeIsCI
        then EmitRangeCPrim (InvertCase (b)); //###0.930
      end
     else
     begin
       {$IFDEF UseAsserts}
       Assert (RangeLen > 0, 'TRegExpr.ParseAtom(subroutine EmitRangeC): empty range'); // impossible, but who knows..
       Assert (RangeChMin <= RangeChMax, 'TRegExpr.ParseAtom(subroutine EmitRangeC): RangeChMin > RangeChMax'); // impossible, but who knows..
       {$ENDIF}
       if RangeLen <= TinySetLen then begin // emit "tiny set"
          if FRegcode = @FRegdummy then begin
            FRegsize := RangePCodeIdx + TinySetLen; // RangeChMin/Max !!!
            Exit;
           end;
          FRegcode := RangePCodeBeg;
          for Ch := RangeChMin to RangeChMax do //###0.930
           if Ch in RangeSet then begin
             FRegcode^ := Ch;
             Inc (FRegcode);
            end;
          // fill rest:
          while FRegcode < RangePCodeBeg + TinySetLen do
          begin
            FRegcode^ := RangeChMax;
            Inc (FRegcode);
           end;
         end
        else
        begin
          if FRegcode = @FRegdummy then begin
            FRegsize := RangePCodeIdx + SizeOf (TSetOfREChar);
            Exit;
           end;
          if (RangePCodeBeg - REOpSz - RENextOffSz)^ = ANYBUTTINYSET
           then RangeSet := [#0 .. #255] - RangeSet;
          PREOp (RangePCodeBeg - REOpSz - RENextOffSz)^ := ANYOFFULLSET;
          FRegcode := RangePCodeBeg;
          Move (RangeSet, FRegcode^, SizeOf (TSetOfREChar));
          Inc (FRegcode, SizeOf (TSetOfREChar));
         end;
      end;
   {$ELSE}
   EmitC (b);
   {$ENDIF}
  end;

 procedure EmitSimpleRangeC (b : REChar);
  begin
   RangeBeg := b;
   EmitRangeC (b);
   CanBeRange := True;
  end;

 procedure EmitRangeStr (const s : RegExprString);
  var i : Integer;
  begin
   for i := 1 to length (s)
    do EmitRangeC (s [i]);
  end;

 function UnQuoteChar (var APtr : PRegExprChar) : REChar; //###0.934
  begin
   case APtr^ of
     't': Result := #$9;  // tab (HT/TAB)
     'n': Result := #$a;  // newline (NL)
     'r': Result := #$d;  // car.return (CR)
     'f': Result := #$c;  // form feed (FF)
     'a': Result := #$7;  // alarm (bell) (BEL)
     'e': Result := #$1b; // escape (ESC)
     'x': begin // hex char
       Result := #0;
       Inc (APtr);
       if APtr^ = #0 then begin
         Error (reeNoHexCodeAfterBSlashX);
         Exit;
        end;
       if APtr^ = '{' then begin // \x{nnnn} //###0.936
          repeat
           Inc (APtr);
           if APtr^ = #0 then begin
             Error (reeNoHexCodeAfterBSlashX);
             Exit;
            end;
           if APtr^ <> '}' then begin
              if (Ord (Result)
                  ShR (SizeOf (REChar) * 8 - 4)) and $F <> 0 then begin
                Error (reeHexCodeAfterBSlashXTooBig);
                Exit;
               end;
              Result := REChar ((Ord (Result) shl 4) or HexDig (APtr^));
              // HexDig will cause Error if bad hex digit found
             end
            else Break;
          until False;
         end
        else
        begin
          Result := REChar (HexDig (APtr^));
          // HexDig will cause Error if bad hex digit found
          Inc (APtr);
          if APtr^ = #0 then begin
            Error (reeNoHexCodeAfterBSlashX);
            Exit;
           end;
          Result := REChar ((Ord (Result) shl 4) or HexDig (APtr^));
          // HexDig will cause Error if bad hex digit found
         end;
      end;
     else Result := APtr^;
    end;
  end;

 begin
  Result := nil;
  flagp := WORST; // Tentatively.

  Inc (FRegParse);
  case (FRegParse - 1)^ of
    '^': if ((FCompModifiers and MaskModM) = 0)
           or ((FLineSeparators = '') and not FLinePairedSeparatorAssigned)
          then ret := EmitNode (BOL)
          else ret := EmitNode (BOLML);
    '$': if ((FCompModifiers and MaskModM) = 0)
           or ((FLineSeparators = '') and not FLinePairedSeparatorAssigned)
          then ret := EmitNode (EOL)
          else ret := EmitNode (EOLML);
    '.':
       if (FCompModifiers and MaskModS) <> 0 then begin
          ret := EmitNode (ANY);
          flagp := flagp or HASWIDTH or SIMPLE;
         end
        else
        begin // not /s, so emit [^:LineSeparators:]
          ret := EmitNode (ANYML);
          flagp := flagp or HASWIDTH; // not so simple ;)
//          ret := EmitRange (ANYBUT);
//          EmitRangeStr (LineSeparators); //###0.941
//          EmitRangeStr (LinePairedSeparator); // !!! isn't correct if have to accept only paired
//          EmitRangeC (#0);
//          flagp := flagp or HASWIDTH or SIMPLE;
         end;
    '[': begin
        if FRegParse^ = '^' then begin // Complement of range.
           if (FCompModifiers and MaskModI) <> 0
            then ret := EmitRange (ANYBUTCI)
            else ret := EmitRange (ANYBUT);
           Inc (FRegParse);
          end
         else
          if (FCompModifiers and MaskModI) <> 0
           then ret := EmitRange (ANYOFCI)
           else ret := EmitRange (ANYOF);

        CanBeRange := False;

        if (FRegParse^ = ']') then begin
          EmitSimpleRangeC (FRegParse^); // []-a] -> ']' .. 'a'
          Inc (FRegParse);
         end;

        while (FRegParse^ <> #0) and (FRegParse^ <> ']') do
        begin
          if (FRegParse^ = '-')
              and ((FRegParse + 1)^ <> #0) and ((FRegParse + 1)^ <> ']')
              and CanBeRange then begin
             Inc (FRegParse);
             RangeEnd := FRegParse^;
             if RangeEnd = EscChar then begin
               {$IFDEF SynRegUniCode} //###0.935
               if (ord ((FRegParse + 1)^) < 256)
                  and (ansichar ((FRegParse + 1)^)
                        in ['d', 'D', 's', 'S', 'w', 'W']) then begin
               {$ELSE}
               if (FRegParse + 1)^ in ['d', 'D', 's', 'S', 'w', 'W'] then begin
               {$ENDIF}
                 EmitRangeC ('-'); // or treat as error ?!!
                 CONTINUE;
                end;
               Inc (FRegParse);
               RangeEnd := UnQuoteChar (FRegParse);
              end;

             // r.e.ranges extension for russian
             if ((FCompModifiers and MaskModR) <> 0)
                and (RangeBeg = RusRangeLoLow) and (RangeEnd = RusRangeLoHigh) then begin
               EmitRangeStr (RusRangeLo);
              end
             else if ((FCompModifiers and MaskModR) <> 0)
                 and (RangeBeg = RusRangeHiLow) and (RangeEnd = RusRangeHiHigh) then begin
               EmitRangeStr (RusRangeHi);
              end
             else if ((FCompModifiers and MaskModR) <> 0)
                  and (RangeBeg = RusRangeLoLow) and (RangeEnd = RusRangeHiHigh) then begin
               EmitRangeStr (RusRangeLo);
               EmitRangeStr (RusRangeHi);
              end
             else
             begin // standard r.e. handling
               if RangeBeg > RangeEnd then begin
                 Error (reeInvalidRange);
                 Exit;
                end;
               Inc (RangeBeg);
               EmitRangeC (RangeEnd); // prevent infinite loop if RangeEnd=$ff
               while RangeBeg < RangeEnd do //###0.929
               begin
                 EmitRangeC (RangeBeg);
                 Inc (RangeBeg);
                end;
              end;
             Inc (FRegParse);
            end
           else
           begin
             if FRegParse^ = EscChar then begin
                Inc (FRegParse);
                if FRegParse^ = #0 then begin
                  Error (reeParseAtomTrailingBackSlash);
                  Exit;
                 end;
                case FRegParse^ of // r.e.extensions
                  'd': EmitRangeStr ('0123456789');
                  'w': EmitRangeStr (WordChars);
                  's': EmitRangeStr (SpaceChars);
                  else EmitSimpleRangeC (UnQuoteChar (FRegParse));
                 end; { of case}
               end
              else EmitSimpleRangeC (FRegParse^);
             Inc (FRegParse);
            end;
         end; { of while}
        EmitRangeC (#0);
        if FRegParse^ <> ']' then begin
          Error (reeUnmatchedSqBrackets);
          Exit;
         end;
        Inc (FRegParse);
        flagp := flagp or HASWIDTH or SIMPLE;
      end;
    '(': begin
        if FRegParse^ = '?' then begin
           // check for extended Perl syntax : (?..)
           if (FRegParse + 1)^ = '#' then begin // (?#comment)
              Inc (FRegParse, 2); // find closing ')'
              while (FRegParse^ <> #0) and (FRegParse^ <> ')')
               do Inc (FRegParse);
              if FRegParse^ <> ')' then begin
                Error (reeUnclosedComment);
                Exit;
               end;
              Inc (FRegParse); // skip ')'
              ret := EmitNode (COMMENT); // comment
             end
           else
           begin // modifiers ?
             Inc (FRegParse); // skip '?'
             begmodfs := FRegParse;
             while (FRegParse^ <> #0) and (FRegParse^ <> ')')
              do Inc (FRegParse);
             if (FRegParse^ <> ')')
                or not ParseModifiersStr (copy (begmodfs, 1, (FRegParse - begmodfs)), FCompModifiers) then begin
               Error (reeUrecognizedModifier);
               Exit;
              end;
             Inc (FRegParse); // skip ')'
             ret := EmitNode (COMMENT); // comment
//             Error (reeQPSBFollowsNothing);
//             Exit;
            end;
          end
         else
         begin
           ret := ParseReg (1, flags);
           if ret = nil then begin
             Result := nil;
             Exit;
            end;
           flagp := flagp or flags and (HASWIDTH or SPSTART);
          end;
      end;
    #0, '|', ')': begin // Supposed to be caught earlier.
       Error (reeInternalUrp);
       Exit;
      end;
    '?', '+', '*': begin
       Error (reeQPSBFollowsNothing);
       Exit;
      end;
    EscChar: begin
        if FRegParse^ = #0 then begin
          Error (reeTrailingBackSlash);
          Exit;
         end;
        case FRegParse^ of // r.e.extensions
          'b': ret := EmitNode (BOUND); //###0.943
          'B': ret := EmitNode (NOTBOUND); //###0.943
          'A': ret := EmitNode (BOL); //###0.941
          'Z': ret := EmitNode (EOL); //###0.941
          'd': begin // r.e.extension - any digit ('0' .. '9')
             ret := EmitNode (ANYDIGIT);
             flagp := flagp or HASWIDTH or SIMPLE;
            end;
          'D': begin // r.e.extension - not digit ('0' .. '9')
             ret := EmitNode (NOTDIGIT);
             flagp := flagp or HASWIDTH or SIMPLE;
            end;
          's': begin // r.e.extension - any space char
             {$IFDEF UseSetOfChar}
             ret := EmitRange (ANYOF);
             EmitRangeStr (SpaceChars);
             EmitRangeC (#0);
             {$ELSE}
             ret := EmitNode (ANYSPACE);
             {$ENDIF}
             flagp := flagp or HASWIDTH or SIMPLE;
            end;
          'S': begin // r.e.extension - not space char
             {$IFDEF UseSetOfChar}
             ret := EmitRange (ANYBUT);
             EmitRangeStr (SpaceChars);
             EmitRangeC (#0);
             {$ELSE}
             ret := EmitNode (NOTSPACE);
             {$ENDIF}
             flagp := flagp or HASWIDTH or SIMPLE;
            end;
          'w': begin // r.e.extension - any english char / digit / '_'
             {$IFDEF UseSetOfChar}
             ret := EmitRange (ANYOF);
             EmitRangeStr (WordChars);
             EmitRangeC (#0);
             {$ELSE}
             ret := EmitNode (ANYLETTER);
             {$ENDIF}
             flagp := flagp or HASWIDTH or SIMPLE;
            end;
          'W': begin // r.e.extension - not english char / digit / '_'
             {$IFDEF UseSetOfChar}
             ret := EmitRange (ANYBUT);
             EmitRangeStr (WordChars);
             EmitRangeC (#0);
             {$ELSE}
             ret := EmitNode (NOTLETTER);
             {$ENDIF}
             flagp := flagp or HASWIDTH or SIMPLE;
            end;
           '1' .. '9': begin //###0.936
             if (FCompModifiers and MaskModI) <> 0
              then ret := EmitNode (BSUBEXPCI)
              else ret := EmitNode (BSUBEXP);
             EmitC (REChar (ord (FRegParse^) - ord ('0')));
             flagp := flagp or HASWIDTH or SIMPLE;
            end;
          else EmitExactly (UnQuoteChar (FRegParse));
         end; { of case}
        Inc (FRegParse);
      end;
    else
    begin
      Dec (FRegParse);
      if ((FCompModifiers and MaskModX) <> 0) and // check for eXtended syntax
          ((FRegParse^ = '#')
           or ({$IFDEF SynRegUniCode}StrScan (XIgnoredChars, FRegParse^) <> nil //###0.947
               {$ELSE}FRegParse^ in XIgnoredChars{$ENDIF})) then begin //###0.941 \x
         if FRegParse^ = '#' then begin // Skip eXtended comment
            // find comment terminator (group of \n and/or \r)
            while (FRegParse^ <> #0) and (FRegParse^ <> #$d) and (FRegParse^ <> #$a)
             do Inc (FRegParse);
            while (FRegParse^ = #$d) or (FRegParse^ = #$a) // skip comment terminator
             do Inc (FRegParse); // attempt to support different type of line separators
           end
          else
          begin // Skip the blanks!
            while {$IFDEF SynRegUniCode}StrScan (XIgnoredChars, FRegParse^) <> nil //###0.947
                  {$ELSE}FRegParse^ in XIgnoredChars{$ENDIF}
             do Inc (FRegParse);
           end;
         ret := EmitNode (COMMENT); // comment
        end
       else
       begin
         len := strcspn (FRegParse, META);
         if len <= 0 then
          if FRegParse^ <> '{' then begin
             Error (reeRarseAtomInternalDisaster);
             Exit;
            end
           else len := strcspn (FRegParse + 1, META) + 1; // bad {n,m} - compile as EXATLY
         ender := (FRegParse + len)^;
         if (len > 1)
            and ((ender = '*') or (ender = '+') or (ender = '?') or (ender = '{'))
          then Dec (len); // Back off clear of ?+*{ operand.
         flagp := flagp or HASWIDTH;
         if len = 1
         then flagp := flagp or SIMPLE;
         if (FCompModifiers and MaskModI) <> 0
          then ret := EmitNode (EXACTLYCI)
          else ret := EmitNode (EXACTLY);
         while (len > 0)
          and (((FCompModifiers and MaskModX) = 0) or (FRegParse^ <> '#')) do
          begin
           if ((FCompModifiers and MaskModX) = 0) or not ( //###0.941
              {$IFDEF SynRegUniCode}StrScan (XIgnoredChars, FRegParse^) <> nil //###0.947
              {$ELSE}FRegParse^ in XIgnoredChars{$ENDIF} )
            then EmitC (FRegParse^);
           Inc (FRegParse);
           Dec (len);
          end;
         EmitC (#0);
        end; { of if not comment}
     end; { of case else}
   end; { of case}

  Result := ret;
 end; { of function TRegExpr.ParseAtom
--------------------------------------------------------------}

function TRegExpr.GetCompilerErrorPos : Integer;
 begin
  Result := 0;
  if (FRegexpbeg = nil) or (FRegParse = nil)
   then Exit; // not in compiling mode ?
  Result := FRegParse - FRegexpbeg;
 end; { of function TRegExpr.GetCompilerErrorPos
--------------------------------------------------------------}


{=============================================================}
{===================== Matching section ======================}
{=============================================================}

{$IFNDEF UseSetOfChar}
function TRegExpr.StrScanCI (s : PRegExprChar; ch : REChar) : PRegExprChar; //###0.928 - now method of TRegExpr
 begin
  while (s^ <> #0) and (s^ <> ch) and (s^ <> InvertCase (ch))
   do Inc (s);
  if s^ <> #0
   then Result := s
   else Result := nil;
 end; { of function TRegExpr.StrScanCI
--------------------------------------------------------------}
{$ENDIF}

function TRegExpr.regrepeat (p : PRegExprChar; AMax : Integer) : Integer;
// repeatedly match something simple, report how many
 var
  scan : PRegExprChar;
  opnd : PRegExprChar;
  TheMax : Integer;
  {Ch,} InvCh : REChar; //###0.931
  sestart, seend : PRegExprChar; //###0.936
 begin
  Result := 0;
  scan := FRegInput;
  opnd := p + REOpSz + RENextOffSz; //OPERAND
  TheMax := FInputEnd - scan;
  if TheMax > AMax
   then TheMax := AMax;
  case PREOp (p)^ of
    ANY: begin
    // note - ANYML cannot be proceeded in regrepeat because can skip
    // more than one char at once
      Result := TheMax;
      Inc (scan, Result);
     end;
    EXACTLY: begin // in opnd can be only ONE char !!!
//      Ch := opnd^; // store in register //###0.931
      while (Result < TheMax) and (opnd^ = scan^) do
      begin
        Inc (Result);
        Inc (scan);
       end;
     end;
    EXACTLYCI: begin // in opnd can be only ONE char !!!
//      Ch := opnd^; // store in register //###0.931
      while (Result < TheMax) and (opnd^ = scan^) do // prevent unneeded InvertCase //###0.931
      begin
        Inc (Result);
        Inc (scan);
       end;
      if Result < TheMax then begin //###0.931
        InvCh := InvertCase (opnd^); // store in register
        while (Result < TheMax) and ((opnd^ = scan^) or (InvCh = scan^)) do
        begin
          Inc (Result);
          Inc (scan);
        end;
       end;
     end;
    BSUBEXP: begin //###0.936
      sestart := startp [ord (opnd^)];
      if sestart = nil
       then Exit;
      seend := endp [ord (opnd^)];
      if seend = nil
       then Exit;
      repeat
        opnd := sestart;
        while opnd < seend do
        begin
          if (scan >= FInputEnd) or (scan^ <> opnd^) then
            Exit;
          Inc (scan);
          Inc (opnd);
        end;
        Inc (Result);
        FRegInput := scan;
      until Result >= AMax;
     end;
    BSUBEXPCI: begin //###0.936
      sestart := startp [ord (opnd^)];
      if sestart = nil
       then Exit;
      seend := endp [ord (opnd^)];
      if seend = nil
       then Exit;
      repeat
        opnd := sestart;
        while opnd < seend do
        begin
          if (scan >= FInputEnd) or
             ((scan^ <> opnd^) and (scan^ <> InvertCase (opnd^)))
           then Exit;
          Inc (scan);
          Inc (opnd);
         end;
        Inc (Result);
        FRegInput := scan;
      until Result >= AMax;
     end;
    ANYDIGIT:
      while (Result < TheMax) and (scan^ >= '0') and (scan^ <= '9') do
      begin
        Inc (Result);
        Inc (scan);
      end;
    NOTDIGIT:
      while (Result < TheMax) and ((scan^ < '0') or (scan^ > '9')) do
      begin
        Inc (Result);
        Inc (scan);
      end;
    {$IFNDEF UseSetOfChar} //###0.929
    ANYLETTER:
      while (Result < TheMax) and
       (Pos (scan^, FWordChars) > 0) //###0.940
     {  ((scan^ >= 'a') and (scan^ <= 'z') !! I've forgotten (>='0') and (<='9')
       or (scan^ >= 'A') and (scan^ <= 'Z') or (scan^ = '_'))} do
      begin
        Inc (Result);
        Inc (scan);
      end;
    NOTLETTER:
      while (Result < TheMax) and (Pos (scan^, FWordChars) <= 0)  //###0.940
     {   not ((scan^ >= 'a') and (scan^ <= 'z') !! I've forgotten (>='0') and (<='9')
         or (scan^ >= 'A') and (scan^ <= 'Z')
         or (scan^ = '_'))} do
      begin
        Inc (Result);
        Inc (scan);
      end;
    ANYSPACE:
      while (Result < TheMax) and (Pos (scan^, FSpaceChars) > 0) do
      begin
        Inc (Result);
        Inc (scan);
      end;
    NOTSPACE:
      while (Result < TheMax) and (Pos (scan^, FSpaceChars) <= 0) do
      begin
        Inc (Result);
        Inc (scan);
      end;
    {$ENDIF}
    ANYOFTINYSET: begin
      while (Result < TheMax) and //!!!TinySet
       ((scan^ = opnd^) or (scan^ = (opnd + 1)^) or (scan^ = (opnd + 2)^)) do
      begin
        Inc (Result);
        Inc (scan);
       end;
     end;
    ANYBUTTINYSET:
      begin
        while (Result < TheMax) and //!!!TinySet
         (scan^ <> opnd^) and (scan^ <> (opnd + 1)^)
          and (scan^ <> (opnd + 2)^) do
        begin
          Inc (Result);
          Inc (scan);
        end;
      end;
    {$IFDEF UseSetOfChar} //###0.929
    ANYOFFULLSET:
      begin
        while (Result < TheMax) and (scan^ in PSetOfREChar (opnd)^) do
        begin
          Inc (Result);
          Inc (scan);
        end;
      end;
    {$ELSE}
    ANYOF:
      while (Result < TheMax) and (StrScan (opnd, scan^) <> nil) do
      begin
        Inc (Result);
        Inc (scan);
      end;
    ANYBUT:
      while (Result < TheMax) and (StrScan (opnd, scan^) = nil) do
      begin
        Inc (Result);
        Inc (scan);
      end;
    ANYOFCI:
      while (Result < TheMax) and (StrScanCI (opnd, scan^) <> nil) do
      begin
        Inc (Result);
        Inc (scan);
      end;
    ANYBUTCI:
      while (Result < TheMax) and (StrScanCI (opnd, scan^) = nil) do
      begin
        Inc (Result);
        Inc (scan);
      end;
    {$ENDIF}
    else
    begin // Oh dear. Called inappropriately.
      Result := 0; // Best compromise.
      Error (reeRegRepeatCalledInappropriately);
      Exit;
    end;
   end; { of case}
  FRegInput := scan;
 end; { of function TRegExpr.regrepeat
--------------------------------------------------------------}

function TRegExpr.regnext (p : PRegExprChar) : PRegExprChar;
// dig the "next" pointer out of a node
var offset : TRENextOff;
begin
  if p = @FRegdummy then
  begin
    Result := nil;
    Exit;
  end;
  offset := PRENextOff (p + REOpSz)^; //###0.933 inlined NEXT
  if offset = 0 then
    Result := nil
  else
    Result := p + offset;
end; { of function TRegExpr.regnext
--------------------------------------------------------------}

function TRegExpr.MatchPrim (prog : PRegExprChar) : Boolean;
// recursively matching routine
// Conceptually the strategy is simple:  check to see whether the current
// node matches, call self recursively to see whether the rest matches,
// and then act accordingly.  In practice we make some effort to avoid
// recursion, in particular by going through "ordinary" nodes (that don't
// need to know whether the rest of the match failed) by a loop instead of
// by recursion.
 var
  scan : PRegExprChar; // Current node.
  next : PRegExprChar; // Next node.
  len : Integer;
  opnd : PRegExprChar;
  no : Integer;
  save : PRegExprChar;
  nextch : REChar;
  BracesMin, BracesMax : Integer; // we use Integer instead of TREBracesArg for better support */+
  {$IFDEF ComplexBraces}
  SavedLoopStack : array [1 .. LoopStackMax] of Integer; // :(( very bad for recursion
  SavedLoopStackIdx : Integer; //###0.925
  {$ENDIF}
 begin
  Result := False;
  scan := prog;

  while scan <> nil do
  begin
     len := PRENextOff (scan + 1)^; //###0.932 inlined regnext
     if len = 0
      then next := nil
      else next := scan + len;

     case scan^ of
         NOTBOUND, //###0.943 //!!! think about UseSetOfChar !!!
         BOUND:
         if (scan^ = BOUND)
          xor (
          ((FRegInput = FInputStart) or (Pos ((FRegInput - 1)^, FWordChars) <= 0))
            and (FRegInput^ <> #0) and (Pos (FRegInput^, FWordChars) > 0)
           or
            (FRegInput <> FInputStart) and (Pos ((FRegInput - 1)^, FWordChars) > 0)
            and ((FRegInput^ = #0) or (Pos (FRegInput^, FWordChars) <= 0)))
          then Exit;

         BOL: if FRegInput <> FInputStart
               then Exit;
         EOL: if FRegInput^ <> #0
               then Exit;
         BOLML: if FRegInput > FInputStart then begin
            nextch := (FRegInput - 1)^;
            if (nextch <> FLinePairedSeparatorTail)
               or ((FRegInput - 1) <= FInputStart)
               or ((FRegInput - 2)^ <> FLinePairedSeparatorHead)
              then begin
               if (nextch = FLinePairedSeparatorHead)
                 and (FRegInput^ = FLinePairedSeparatorTail)
                then Exit; // don't stop between paired separator
               if
                 {$IFNDEF SynRegUniCode}
                 not (nextch in FLineSeparatorsSet)
                 {$ELSE}
                 (pos (nextch, FLineSeparators) <= 0)
                 {$ENDIF}
                then Exit;
              end;
           end;
         EOLML: if FRegInput^ <> #0 then begin
            nextch := FRegInput^;
            if (nextch <> FLinePairedSeparatorHead)
               or ((FRegInput + 1)^ <> FLinePairedSeparatorTail)
             then begin
               if (nextch = FLinePairedSeparatorTail)
                 and (FRegInput > FInputStart)
                 and ((FRegInput - 1)^ = FLinePairedSeparatorHead)
                then Exit; // don't stop between paired separator
               if
                 {$IFNDEF SynRegUniCode}
                 not (nextch in FLineSeparatorsSet)
                 {$ELSE}
                 (pos (nextch, FLineSeparators) <= 0)
                 {$ENDIF}
                then Exit;
              end;
           end;
         ANY: begin
            if FRegInput^ = #0
             then Exit;
            Inc (FRegInput);
           end;
         ANYML: begin //###0.941
            if (FRegInput^ = #0)
             or ((FRegInput^ = FLinePairedSeparatorHead)
                 and ((FRegInput + 1)^ = FLinePairedSeparatorTail))
             or {$IFNDEF SynRegUniCode} (FRegInput^ in FLineSeparatorsSet)
                {$ELSE} (pos (FRegInput^, FLineSeparators) > 0) {$ENDIF}
             then Exit;
            Inc (FRegInput);
           end;
         ANYDIGIT: begin
            if (FRegInput^ = #0) or (FRegInput^ < '0') or (FRegInput^ > '9')
             then Exit;
            Inc (FRegInput);
           end;
         NOTDIGIT: begin
            if (FRegInput^ = #0) or ((FRegInput^ >= '0') and (FRegInput^ <= '9'))
             then Exit;
            Inc (FRegInput);
           end;
         {$IFNDEF UseSetOfChar} //###0.929
         ANYLETTER: begin
            if (FRegInput^ = #0) or (Pos (FRegInput^, FWordChars) <= 0) //###0.943
             then Exit;
            Inc (FRegInput);
           end;
         NOTLETTER: begin
            if (FRegInput^ = #0) or (Pos (FRegInput^, FWordChars) > 0) //###0.943
             then Exit;
            Inc (FRegInput);
           end;
         ANYSPACE: begin
            if (FRegInput^ = #0) or not (Pos (FRegInput^, FSpaceChars) > 0) //###0.943
             then Exit;
            Inc (FRegInput);
           end;
         NOTSPACE: begin
            if (FRegInput^ = #0) or (Pos (FRegInput^, FSpaceChars) > 0) //###0.943
             then Exit;
            Inc (FRegInput);
           end;
         {$ENDIF}
         EXACTLYCI: begin
            opnd := scan + REOpSz + RENextOffSz; // OPERAND
            // Inline the first character, for speed.
            if (opnd^ <> FRegInput^)
               and (InvertCase (opnd^) <> FRegInput^)
             then Exit;
            len := strlen (opnd);
            //###0.929 begin
            no := len;
            save := FRegInput;
            while no > 1 do
            begin
              Inc (save);
              Inc (opnd);
              if (opnd^ <> save^)
                 and (InvertCase (opnd^) <> save^)
               then Exit;
              Dec (no);
             end;
            //###0.929 end
            Inc (FRegInput, len);
           end;
         EXACTLY: begin
            opnd := scan + REOpSz + RENextOffSz; // OPERAND
            // Inline the first character, for speed.
            if opnd^ <> FRegInput^
             then Exit;
            len := strlen (opnd);
            //###0.929 begin
            no := len;
            save := FRegInput;
            while no > 1 do
            begin
              Inc (save);
              Inc (opnd);
              if opnd^ <> save^
               then Exit;
              Dec (no);
             end;
            //###0.929 end
            Inc (FRegInput, len);
           end;
         BSUBEXP: begin //###0.936
           no := ord ((scan + REOpSz + RENextOffSz)^);
           if startp [no] = nil
            then Exit;
           if endp [no] = nil
            then Exit;
           save := FRegInput;
           opnd := startp [no];
           while opnd < endp [no] do
           begin
             if (save >= FInputEnd) or (save^ <> opnd^)
              then Exit;
             Inc (save);
             Inc (opnd);
            end;
           FRegInput := save;
          end;
         BSUBEXPCI: begin //###0.936
           no := ord ((scan + REOpSz + RENextOffSz)^);
           if startp [no] = nil
            then Exit;
           if endp [no] = nil
            then Exit;
           save := FRegInput;
           opnd := startp [no];
           while opnd < endp [no] do
           begin
             if (save >= FInputEnd) or
                ((save^ <> opnd^) and (save^ <> InvertCase (opnd^)))
              then Exit;
             Inc (save);
             Inc (opnd);
            end;
           FRegInput := save;
          end;
         ANYOFTINYSET: begin
           if (FRegInput^ = #0) or //!!!TinySet
             ((FRegInput^ <> (scan + REOpSz + RENextOffSz)^)
             and (FRegInput^ <> (scan + REOpSz + RENextOffSz + 1)^)
             and (FRegInput^ <> (scan + REOpSz + RENextOffSz + 2)^))
            then Exit;
           Inc (FRegInput);
          end;
         ANYBUTTINYSET: begin
           if (FRegInput^ = #0) or //!!!TinySet
             (FRegInput^ = (scan + REOpSz + RENextOffSz)^)
             or (FRegInput^ = (scan + REOpSz + RENextOffSz + 1)^)
             or (FRegInput^ = (scan + REOpSz + RENextOffSz + 2)^)
            then Exit;
           Inc (FRegInput);
          end;
         {$IFDEF UseSetOfChar} //###0.929
         ANYOFFULLSET: begin
           if (FRegInput^ = #0)
              or not (FRegInput^ in PSetOfREChar (scan + REOpSz + RENextOffSz)^)
            then Exit;
           Inc (FRegInput);
          end;
         {$ELSE}
         ANYOF: begin
            if (FRegInput^ = #0) or (StrScan (scan + REOpSz + RENextOffSz, FRegInput^) = nil)
             then Exit;
            Inc (FRegInput);
           end;
         ANYBUT: begin
            if (FRegInput^ = #0) or (StrScan (scan + REOpSz + RENextOffSz, FRegInput^) <> nil)
             then Exit;
            Inc (FRegInput);
           end;
         ANYOFCI: begin
            if (FRegInput^ = #0) or (StrScanCI (scan + REOpSz + RENextOffSz, FRegInput^) = nil)
             then Exit;
            Inc (FRegInput);
           end;
         ANYBUTCI: begin
            if (FRegInput^ = #0) or (StrScanCI (scan + REOpSz + RENextOffSz, FRegInput^) <> nil)
             then Exit;
            Inc (FRegInput);
           end;
         {$ENDIF}
         NOTHING: ;
         COMMENT: ;
         BACK: ;
         Succ (OPEN) .. TREOp (Ord (OPEN) + NSUBEXP - 1) : begin //###0.929
            no := ord (scan^) - ord (OPEN);
//            save := FRegInput;
            save := startp [no]; //###0.936
            startp [no] := FRegInput; //###0.936
            Result := MatchPrim (next);
            if not Result //###0.936
             then startp [no] := save;
//            if Result and (startp [no] = nil)
//             then startp [no] := save;
             // Don't set startp if some later invocation of the same
             // parentheses already has.
            Exit;
           end;
         Succ (CLOSE) .. TREOp (Ord (CLOSE) + NSUBEXP - 1): begin //###0.929
            no := ord (scan^) - ord (CLOSE);
//            save := FRegInput;
            save := endp [no]; //###0.936
            endp [no] := FRegInput; //###0.936
            Result := MatchPrim (next);
            if not Result //###0.936
             then endp [no] := save;
//            if Result and (endp [no] = nil)
//             then endp [no] := save;
             // Don't set endp if some later invocation of the same
             // parentheses already has.
            Exit;
           end;
         BRANCH: begin
            if (next^ <> BRANCH) // No choice.
             then next := scan + REOpSz + RENextOffSz // Avoid recursion
             else
             begin
               repeat
                save := FRegInput;
                Result := MatchPrim (scan + REOpSz + RENextOffSz);
                if Result
                 then Exit;
                FRegInput := save;
                scan := regnext (scan);
               until (scan = nil) or (scan^ <> BRANCH);
               Exit;
              end;
           end;
         {$IFDEF ComplexBraces}
         LOOPENTRY: begin //###0.925
           no := LoopStackIdx;
           Inc (LoopStackIdx);
           if LoopStackIdx > LoopStackMax then begin
             Error (reeLoopStackExceeded);
             Exit;
            end;
           save := FRegInput;
           LoopStack [LoopStackIdx] := 0; // init loop counter
           Result := MatchPrim (next); // execute LOOP
           LoopStackIdx := no; // cleanup
           if Result
            then Exit;
           FRegInput := save;
           Exit;
          end;
         LOOP, LOOPNG: begin //###0.940
           if LoopStackIdx <= 0 then begin
             Error (reeLoopWithoutEntry);
             Exit;
            end;
           opnd := scan + PRENextOff (scan + REOpSz + RENextOffSz + 2 * REBracesArgSz)^;
           BracesMin := PREBracesArg (scan + REOpSz + RENextOffSz)^;
           BracesMax := PREBracesArg (scan + REOpSz + RENextOffSz + REBracesArgSz)^;
           save := FRegInput;
           if LoopStack [LoopStackIdx] >= BracesMin then begin // Min alredy matched - we can work
              if scan^ = LOOP then begin
                 // greedy way - first try to max deep of greed ;)
                 if LoopStack [LoopStackIdx] < BracesMax then begin
                   Inc (LoopStack [LoopStackIdx]);
                   no := LoopStackIdx;
                   Result := MatchPrim (opnd);
                   LoopStackIdx := no;
                   if Result
                    then Exit;
                   FRegInput := save;
                  end;
                 Dec (LoopStackIdx); // Fail. May be we are too greedy? ;)
                 Result := MatchPrim (next);
                 if not Result
                  then FRegInput := save;
                 Exit;
                end
               else
               begin
                 // non-greedy - try just now
                 Result := MatchPrim (next);
                 if Result
                  then Exit
                  else FRegInput := save; // failed - move next and try again
                 if LoopStack [LoopStackIdx] < BracesMax then
                 begin
                   Inc (LoopStack [LoopStackIdx]);
                   no := LoopStackIdx;
                   Result := MatchPrim (opnd);
                   LoopStackIdx := no;
                   if Result then
                     Exit;
                   FRegInput := save;
                 end;
                 Dec (LoopStackIdx); // Failed - back up
                 Exit;
                end
             end
            else
            begin // first match a min_cnt times
              Inc (LoopStack [LoopStackIdx]);
              no := LoopStackIdx;
              Result := MatchPrim (opnd);
              LoopStackIdx := no;
              if Result
               then Exit;
              Dec (LoopStack [LoopStackIdx]);
              FRegInput := save;
              Exit;
             end;
          end;
         {$ENDIF}
         STAR, PLUS, BRACES, STARNG, PLUSNG, BRACESNG: begin
           // Lookahead to avoid useless match attempts when we know
           // what character comes next.
           nextch := #0;
           if next^ = EXACTLY
            then nextch := (next + REOpSz + RENextOffSz)^;
           BracesMax := MaxInt; // infinite loop for * and + //###0.92
           if (scan^ = STAR) or (scan^ = STARNG)
            then BracesMin := 0  // STAR
            else if (scan^ = PLUS) or (scan^ = PLUSNG)
             then BracesMin := 1 // PLUS
             else
             begin // BRACES
               BracesMin := PREBracesArg (scan + REOpSz + RENextOffSz)^;
               BracesMax := PREBracesArg (scan + REOpSz + RENextOffSz + REBracesArgSz)^;
             end;
           save := FRegInput;
           opnd := scan + REOpSz + RENextOffSz;
           if (scan^ = BRACES) or (scan^ = BRACESNG)
            then Inc (opnd, 2 * REBracesArgSz);

           if (scan^ = PLUSNG) or (scan^ = STARNG) or (scan^ = BRACESNG) then begin
             // non-greedy mode
              BracesMax := regrepeat (opnd, BracesMax); // don't repeat more than BracesMax
              // Now we know real Max limit to move forward (for recursion 'back up')
              // In some cases it can be faster to check only Min positions first,
              // but after that we have to check every position separtely instead
              // of fast scannig in loop.
              no := BracesMin;
              while no <= BracesMax do
              begin
                FRegInput := save + no;
                // If it could work, try it.
                if (nextch = #0) or (FRegInput^ = nextch) then begin
                  {$IFDEF ComplexBraces}
                  System.Move (LoopStack, SavedLoopStack, SizeOf (LoopStack)); //###0.925
                  SavedLoopStackIdx := LoopStackIdx;
                  {$ENDIF}
                  if MatchPrim (next) then begin
                    Result := True;
                    Exit;
                   end;
                  {$IFDEF ComplexBraces}
                  System.Move (SavedLoopStack, LoopStack, SizeOf (LoopStack));
                  LoopStackIdx := SavedLoopStackIdx;
                  {$ENDIF}
                 end;
                Inc (no); // Couldn't or didn't - move forward.
               end; { of while}
              Exit;
             end
            else
            begin // greedy mode
              no := regrepeat (opnd, BracesMax); // don't repeat more than max_cnt
              while no >= BracesMin do
              begin
                // If it could work, try it.
                if (nextch = #0) or (FRegInput^ = nextch) then begin
                  {$IFDEF ComplexBraces}
                  System.Move (LoopStack, SavedLoopStack, SizeOf (LoopStack)); //###0.925
                  SavedLoopStackIdx := LoopStackIdx;
                  {$ENDIF}
                  if MatchPrim (next) then begin
                    Result := True;
                    Exit;
                   end;
                  {$IFDEF ComplexBraces}
                  System.Move (SavedLoopStack, LoopStack, SizeOf (LoopStack));
                  LoopStackIdx := SavedLoopStackIdx;
                  {$ENDIF}
                 end;
                Dec (no); // Couldn't or didn't - back up.
                FRegInput := save + no;
               end; { of while}
              Exit;
             end;
          end;
         EEND: begin
           Result := True;  // Success!
           Exit;
          end;
        else
        begin
            Error (reeMatchPrimMemoryCorruption);
            Exit;
          end;
        end; { of case scan^}
        scan := next;
    end; { of while scan <> nil}

  // We get here only if there's trouble -- normally "case EEND" is the
  // terminating point.
  Error (reeMatchPrimCorruptedPointers);
 end; { of function TRegExpr.MatchPrim
--------------------------------------------------------------}

{$IFDEF UseFirstCharSet} //###0.929
procedure TRegExpr.FillFirstCharSet (prog : PRegExprChar);
 var
  scan : PRegExprChar; // Current node.
  next : PRegExprChar; // Next node.
  opnd : PRegExprChar;
  min_cnt : Integer;
 begin
  scan := prog;
  while scan <> nil do
  begin
     next := regnext (scan);
     case PREOp (scan)^ of
         BSUBEXP, BSUBEXPCI: begin //###0.938
           FFirstCharSet := [#0 .. #255]; // :((( we cannot
           // optimize r.e. if it starts with back reference
           Exit;
          end;
         BOL, BOLML: ; // Exit; //###0.937
         EOL, EOLML: begin //###0.948 was empty in 0.947, was Exit in 0.937
           Include (FFirstCharSet, #0);
           if ModifierM
            then begin
              opnd := PRegExprChar (LineSeparators);
              while opnd^ <> #0 do
              begin
                Include (FFirstCharSet, opnd^);
                Inc (opnd);
              end;
            end;
           Exit;
         end;
         BOUND, NOTBOUND: ; //###0.943 ?!!
         ANY, ANYML: begin // we can better define ANYML !!!
           FFirstCharSet := [#0 .. #255]; //###0.930
           Exit;
          end;
         ANYDIGIT: begin
           FFirstCharSet := FFirstCharSet + ['0' .. '9'];
           Exit;
          end;
         NOTDIGIT: begin
           FFirstCharSet := FFirstCharSet + ([#0 .. #255] - ['0' .. '9']); //###0.948 FFirstCharSet was forgotten
           Exit;
          end;
         EXACTLYCI: begin
           Include (FFirstCharSet, (scan + REOpSz + RENextOffSz)^);
           Include (FFirstCharSet, InvertCase ((scan + REOpSz + RENextOffSz)^));
           Exit;
          end;
         EXACTLY: begin
           Include (FFirstCharSet, (scan + REOpSz + RENextOffSz)^);
           Exit;
          end;
         ANYOFFULLSET: begin
           FFirstCharSet := FFirstCharSet + PSetOfREChar (scan + REOpSz + RENextOffSz)^;
           Exit;
          end;
         ANYOFTINYSET: begin
           //!!!TinySet
           Include (FFirstCharSet, (scan + REOpSz + RENextOffSz)^);
           Include (FFirstCharSet, (scan + REOpSz + RENextOffSz + 1)^);
           Include (FFirstCharSet, (scan + REOpSz + RENextOffSz + 2)^);
           // ...                                                      // up to TinySetLen
           Exit;
          end;
         ANYBUTTINYSET: begin
           //!!!TinySet
           FFirstCharSet := FFirstCharSet + ([#0 .. #255] - [ //###0.948 FFirstCharSet was forgotten
            (scan + REOpSz + RENextOffSz)^,
            (scan + REOpSz + RENextOffSz + 1)^,
            (scan + REOpSz + RENextOffSz + 2)^]);
           // ...                                                      // up to TinySetLen
           Exit;
          end;
         NOTHING: ;
         COMMENT: ;
         BACK: ;
         Succ (OPEN) .. TREOp (Ord (OPEN) + NSUBEXP - 1) : begin //###0.929
            FillFirstCharSet (next);
            Exit;
           end;
         Succ (CLOSE) .. TREOp (Ord (CLOSE) + NSUBEXP - 1): begin //###0.929
            FillFirstCharSet (next);
            Exit;
           end;
         BRANCH: begin
            if (PREOp (next)^ <> BRANCH) // No choice.
             then next := scan + REOpSz + RENextOffSz // Avoid recursion.
             else
             begin
               repeat
                FillFirstCharSet (scan + REOpSz + RENextOffSz);
                scan := regnext (scan);
               until (scan = nil) or (PREOp (scan)^ <> BRANCH);
               Exit;
             end;
           end;
         {$IFDEF ComplexBraces}
         LOOPENTRY: begin //###0.925
//           LoopStack [LoopStackIdx] := 0; //###0.940 line removed
           FillFirstCharSet (next); // execute LOOP
           Exit;
          end;
         LOOP, LOOPNG: begin //###0.940
           opnd := scan + PRENextOff (scan + REOpSz + RENextOffSz + REBracesArgSz * 2)^;
           min_cnt := PREBracesArg (scan + REOpSz + RENextOffSz)^;
           FillFirstCharSet (opnd);
           if min_cnt = 0
            then FillFirstCharSet (next);
           Exit;
          end;
         {$ENDIF}
         STAR, STARNG: //###0.940
           FillFirstCharSet (scan + REOpSz + RENextOffSz);
         PLUS, PLUSNG: begin //###0.940
           FillFirstCharSet (scan + REOpSz + RENextOffSz);
           Exit;
          end;
         BRACES, BRACESNG: begin //###0.940
           opnd := scan + REOpSz + RENextOffSz + REBracesArgSz * 2;
           min_cnt := PREBracesArg (scan + REOpSz + RENextOffSz)^; // BRACES
           FillFirstCharSet (opnd);
           if min_cnt > 0
            then Exit;
          end;
         EEND: begin
            FFirstCharSet := [#0 .. #255]; //###0.948
            Exit;
           end;
        else
          begin
            Error (reeMatchPrimMemoryCorruption);
            Exit;
          end;
        end; { of case scan^}
        scan := next;
    end; { of while scan <> nil}
 end; { of procedure FillFirstCharSet
--------------------------------------------------------------}
{$ENDIF}

function TRegExpr.Exec (const AInputString : RegExprString) : Boolean;
 begin
  InputString := AInputString;
  Result := ExecPrim (1);
 end; { of function TRegExpr.Exec
--------------------------------------------------------------}

{$IFDEF OverMeth}
{$IFNDEF FPC}
function TRegExpr.Exec : Boolean;
 begin
  Result := ExecPrim (1);
 end; { of function TRegExpr.Exec
--------------------------------------------------------------}
{$ENDIF}
function TRegExpr.Exec (AOffset: Integer) : Boolean;
 begin
  Result := ExecPrim (AOffset);
 end; { of function TRegExpr.Exec
--------------------------------------------------------------}
{$ENDIF}

function TRegExpr.ExecPos (AOffset: Integer {$IFDEF DefParam}= 1{$ENDIF}) : Boolean;
 begin
  Result := ExecPrim (AOffset);
 end; { of function TRegExpr.ExecPos
--------------------------------------------------------------}

function TRegExpr.ExecPrim (AOffset: Integer) : Boolean;
 procedure ClearMatchs;
  // Clears matchs array
  var i : Integer;
  begin
   for i := 0 to NSUBEXP - 1 do
   begin
     startp [i] := nil;
     endp [i] := nil;
    end;
  end; { of procedure ClearMatchs;
..............................................................}
 function RegMatch (str : PRegExprChar) : Boolean;
  // try match at specific point
  begin
   //###0.949 removed clearing of start\endp
   FRegInput := str;
   Result := MatchPrim (FProgramm + REOpSz);
   if Result then begin
     startp [0] := str;
     endp [0] := FRegInput;
    end;
  end; { of function RegMatch
..............................................................}
 var
  s : PRegExprChar;
  StartPtr: PRegExprChar;
  InputLen : Integer;
 begin
  Result := False; // Be paranoid...

  ClearMatchs; //###0.949
  // ensure that Match cleared either if optimization tricks or some error
  // will lead to leaving ExecPrim without actual search. That is
  // importent for ExecNext logic and so on.

  if not IsProgrammOk //###0.929
   then Exit;

  // Check InputString presence
  if not Assigned (FInputString) then begin
    Error (reeNoInpitStringSpecified);
    Exit;
   end;

  InputLen := length (FInputString);

  //Check that the start position is not negative
  if AOffset < 1 then begin
    Error (reeOffsetMustBeGreaterThen0);
    Exit;
   end;
  // Check that the start position is not longer than the line
  // If so then Exit with nothing found
  if AOffset > (InputLen + 1) // for matching empty string after last char.
   then Exit;

  StartPtr := FInputString + AOffset - 1;

  // If there is a "must appear" string, look for it.
  if regmust <> nil then begin
    s := StartPtr;
    repeat
     s := StrScan (s, regmust [0]);
     if s <> nil then begin
       if StrLComp (s, regmust, regmlen) = 0
        then Break; // Found it.
       Inc (s);
      end;
    until s = nil;
    if s = nil // Not present.
     then Exit;
   end;

  // Mark beginning of line for ^ .
  FInputStart := FInputString;

  // Pointer to end of input stream - for
  // pascal-style string processing (may include #0)
  FInputEnd := FInputString + InputLen;

  {$IFDEF ComplexBraces}
  // no loops started
  LoopStackIdx := 0; //###0.925
  {$ENDIF}

  // Simplest case:  anchored match need be tried only once.
  if reganch <> #0 then begin
    Result := RegMatch (StartPtr);
    Exit;
   end;

  // Messy cases:  unanchored match.
  s := StartPtr;
  if regstart <> #0 then // We know what char it must start with.
    repeat
     s := StrScan (s, regstart);
     if s <> nil then begin
       Result := RegMatch (s);
       if Result
        then Exit
        else ClearMatchs; //###0.949
       Inc (s);
      end;
    until s = nil
   else
   begin // We don't - general case.
     repeat //###0.948
       {$IFDEF UseFirstCharSet}
       if s^ in FFirstCharSet
        then Result := RegMatch (s);
       {$ELSE}
       Result := RegMatch (s);
       {$ENDIF}
       if Result or (s^ = #0) // Exit on a match or after testing the end-of-string.
        then Exit
        else ClearMatchs; //###0.949
       Inc (s);
     until False;
(*  optimized and fixed by Martin Fuller - empty strings
    were not allowed to pass thru in UseFirstCharSet mode
     {$IFDEF UseFirstCharSet} //###0.929
     while s^ <> #0 do
     begin
       if s^ in FFirstCharSet
        then Result := RegMatch (s);
       if Result
        then Exit;
       Inc (s);
      end;
     {$ELSE}
     repeat
      Result := RegMatch (s);
      if Result
       then Exit;
      Inc (s);
     until s^ = #0;
     {$ENDIF}
*)
    end;
  // Failure
 end; { of function TRegExpr.ExecPrim
--------------------------------------------------------------}

function TRegExpr.ExecNext : Boolean;
 var offset : Integer;
 begin
  Result := False;
  if not Assigned (startp[0]) or not Assigned (endp[0]) then begin
    Error (reeExecNextWithoutExec);
    Exit;
   end;
//  Offset := MatchPos [0] + MatchLen [0];
//  if MatchLen [0] = 0
  Offset := endp [0] - FInputString + 1; //###0.929
  if endp [0] = startp [0] //###0.929
   then Inc (Offset); // prevent infinite looping if empty string match r.e.
  Result := ExecPrim (Offset);
 end; { of function TRegExpr.ExecNext
--------------------------------------------------------------}

function TRegExpr.GetInputString : RegExprString;
 begin
  if not Assigned (FInputString) then begin
    Error (reeGetInputStringWithoutInputString);
    Exit;
   end;
  Result := FInputString;
 end; { of function TRegExpr.GetInputString
--------------------------------------------------------------}

procedure TRegExpr.SetInputString (const AInputString : RegExprString);
 var
  Len : Integer;
  i : Integer;
 begin
  // clear Match* - before next Exec* call it's undefined
  for i := 0 to NSUBEXP - 1 do
  begin
    startp [i] := nil;
    endp [i] := nil;
   end;

  // need reallocation of input string buffer ?
  Len := length (AInputString);
  if Assigned (FInputString) and (Length (FInputString) <> Len) then begin
    FreeMem (FInputString);
    FInputString := nil;
   end;
  // buffer [re]allocation
  if not Assigned (FInputString)
   then GetMem (FInputString, (Len + 1) * SizeOf (REChar));

  // copy input string into buffer
  {$IFDEF SynRegUniCode}
//  StrPCopy (FInputString, Copy (AInputString, 1, Len)); //###0.927
  StrPCopy (FInputString, AInputString); //KV Copy above is wastefull.  Do not really understand why is there.
  {$ELSE}
  StrLCopy (FInputString, PRegExprChar (AInputString), Len);
  {$ENDIF}

  {
  FInputString : string;
  FInputStart, FInputEnd : PRegExprChar;

  SetInputString:
  FInputString := AInputString;
  UniqueString (FInputString);
  FInputStart := PChar (FInputString);
  Len := length (FInputString);
  FInputEnd := PRegExprChar (Integer (FInputStart) + Len); ??
  !! startp/endp ��� ����� ����� ������ ������������ ?
  }
 end; { of procedure TRegExpr.SetInputString
--------------------------------------------------------------}

procedure TRegExpr.SetLineSeparators (const AStr : RegExprString);
 begin
  if AStr <> FLineSeparators then begin
    FLineSeparators := AStr;
    InvalidateProgramm;
   end;
 end; { of procedure TRegExpr.SetLineSeparators
--------------------------------------------------------------}

procedure TRegExpr.SetLinePairedSeparator (const AStr : RegExprString);
 begin
  if length (AStr) = 2 then begin
     if AStr [1] = AStr [2] then begin
      // it's impossible for our 'one-point' checking to support
      // two chars separator for identical chars
       Error (reeBadLinePairedSeparator);
       Exit;
      end;
     if not FLinePairedSeparatorAssigned
      or (AStr [1] <> FLinePairedSeparatorHead)
      or (AStr [2] <> FLinePairedSeparatorTail) then begin
       FLinePairedSeparatorAssigned := True;
       FLinePairedSeparatorHead := AStr [1];
       FLinePairedSeparatorTail := AStr [2];
       InvalidateProgramm;
      end;
    end
   else if length (AStr) = 0 then begin
     if FLinePairedSeparatorAssigned then begin
       FLinePairedSeparatorAssigned := False;
       InvalidateProgramm;
      end;
    end
   else Error (reeBadLinePairedSeparator);
 end; { of procedure TRegExpr.SetLinePairedSeparator
--------------------------------------------------------------}

function TRegExpr.GetLinePairedSeparator : RegExprString;
 begin
  if FLinePairedSeparatorAssigned then begin
     {$IFDEF SynRegUniCode}
     // Here is some UniCode 'magic'
     // If You do know better decision to concatenate
     // two WideChars, please, let me know!
     Result := FLinePairedSeparatorHead; //###0.947
     Result := Result + FLinePairedSeparatorTail;
     {$ELSE}
     Result := FLinePairedSeparatorHead + FLinePairedSeparatorTail;
     {$ENDIF}
    end
   else Result := '';
 end; { of function TRegExpr.GetLinePairedSeparator
--------------------------------------------------------------}

function TRegExpr.Substitute (const ATemplate : RegExprString) : RegExprString;
// perform substitutions after a regexp match
// completely rewritten in 0.929
 var
  TemplateLen : Integer;
  TemplateBeg, TemplateEnd : PRegExprChar;
  p, p0, ResultPtr : PRegExprChar;
  ResultLen : Integer;
  n : Integer;
  Ch : REChar;
 function ParseVarName (var APtr : PRegExprChar) : Integer;
  // extract name of variable (digits, may be enclosed with
  // curly braces) from APtr^, uses TemplateEnd !!!
  const
   Digits = ['0' .. '9'];
  var
   p : PRegExprChar;
   Delimited : Boolean;
  begin
   Result := 0;
   p := APtr;
   Delimited := (p < TemplateEnd) and (p^ = '{');
   if Delimited
    then Inc (p); // skip left curly brace
   if (p < TemplateEnd) and (p^ = '&')
    then Inc (p) // this is '$&' or '${&}'
    else
     while (p < TemplateEnd) and
      {$IFDEF SynRegUniCode} //###0.935
      (ord (p^) < 256) and (ansichar (p^) in Digits)
      {$ELSE}
      (p^ in Digits)
      {$ENDIF}
       do
      begin
       Result := Result * 10 + (ord (p^) - ord ('0')); //###0.939
       Inc (p);
      end;
   if Delimited then
    if (p < TemplateEnd) and (p^ = '}')
     then Inc (p) // skip right curly brace
     else p := APtr; // isn't properly terminated
   if p = APtr
    then Result := -1; // no valid digits found or no right curly brace
   APtr := p;
  end;
 begin
  // Check FProgramm and input string
  if not IsProgrammOk
   then Exit;
  if not Assigned (FInputString) then begin
    Error (reeNoInpitStringSpecified);
    Exit;
   end;
  // Prepare for working
  TemplateLen := length (ATemplate);
  if TemplateLen = 0 then begin // prevent nil pointers
    Result := '';
    Exit;
   end;
  TemplateBeg := pointer (ATemplate);
  TemplateEnd := TemplateBeg + TemplateLen;
  // Count result length for speed optimization.
  ResultLen := 0;
  p := TemplateBeg;
  while p < TemplateEnd do
  begin
    Ch := p^;
    Inc (p);
    if Ch = '$'
     then n := ParseVarName (p)
     else n := -1;
    if n >= 0 then begin
       if (n < NSUBEXP) and Assigned (startp [n]) and Assigned (endp [n])
        then Inc (ResultLen, endp [n] - startp [n]);
      end
     else
     begin
       if (Ch = EscChar) and (p < TemplateEnd) then
         Inc (p); // quoted or special char followed
       Inc (ResultLen);
     end;
   end;
  // Get memory. We do it once and it significant speed up work !
  if ResultLen = 0 then begin
    Result := '';
    Exit;
   end;
  SetString (Result, nil, ResultLen);
  // Fill Result
  ResultPtr := pointer (Result);
  p := TemplateBeg;
  while p < TemplateEnd do
  begin
    Ch := p^;
    Inc (p);
    if Ch = '$'
     then n := ParseVarName (p)
     else n := -1;
    if n >= 0 then begin
       p0 := startp [n];
       if (n < NSUBEXP) and Assigned (p0) and Assigned (endp [n]) then
        while p0 < endp [n] do
        begin
          ResultPtr^ := p0^;
          Inc (ResultPtr);
          Inc (p0);
         end;
      end
     else
     begin
       if (Ch = EscChar) and (p < TemplateEnd) then
       begin // quoted or special char followed
         Ch := p^;
         Inc (p);
       end;
       ResultPtr^ := Ch;
       Inc (ResultPtr);
     end;
   end;
 end; { of function TRegExpr.Substitute
--------------------------------------------------------------}

procedure TRegExpr.Split(AInputStr: RegExprString; APieces: TStrings);
var
  PrevPos: Integer;
begin
  PrevPos := 1;
  if Exec (AInputStr) then
  repeat
    APieces.Add (System.Copy (AInputStr, PrevPos, MatchPos [0] - PrevPos));
    PrevPos := MatchPos [0] + MatchLen [0];
  until not ExecNext;
  APieces.Add (System.Copy (AInputStr, PrevPos, MaxInt)); // Tail
end; { of procedure TRegExpr.Split
--------------------------------------------------------------}

function TRegExpr.Replace (AInputStr : RegExprString; const AReplaceStr : RegExprString;
  AUseSubstitution : Boolean{$IFDEF DefParam}= False{$ENDIF}) : RegExprString;
var
  PrevPos : Integer;
begin
  Result := '';
  PrevPos := 1;
  if Exec (AInputStr) then
  repeat
    Result := Result + System.Copy (AInputStr, PrevPos,
      MatchPos [0] - PrevPos);
    if AUseSubstitution then //###0.946
      Result := Result + Substitute (AReplaceStr)
    else
      Result := Result + AReplaceStr;
    PrevPos := MatchPos [0] + MatchLen [0];
  until not ExecNext;
  Result := Result + System.Copy (AInputStr, PrevPos, MaxInt); // Tail
end; { of function TRegExpr.Replace
--------------------------------------------------------------}

function TRegExpr.ReplaceEx (AInputStr : RegExprString;
      AReplaceFunc : TRegExprReplaceFunction)
     : RegExprString;
var
  PrevPos : Integer;
begin
  Result := '';
  PrevPos := 1;
  if Exec (AInputStr) then
    repeat
      Result := Result + System.Copy (AInputStr, PrevPos, MatchPos [0] - PrevPos) + AReplaceFunc (Self);
      PrevPos := MatchPos [0] + MatchLen [0];
    until not ExecNext;
  Result := Result + System.Copy (AInputStr, PrevPos, MaxInt); // Tail
end; { of function TRegExpr.ReplaceEx
--------------------------------------------------------------}


{$IFDEF OverMeth}
function TRegExpr.Replace (AInputStr: RegExprString;
  AReplaceFunc: TRegExprReplaceFunction): RegExprString;
begin
  ReplaceEx(AInputStr, AReplaceFunc);
end; { of function TRegExpr.Replace
--------------------------------------------------------------}
{$ENDIF}

{=============================================================}
{====================== Debug section ========================}
{=============================================================}

{$IFDEF RegExpPCodeDump}
function TRegExpr.DumpOp (op : TREOp) : RegExprString;
// printable representation of opcode
 begin
  case op of
    BOL:          Result := 'BOL';
    EOL:          Result := 'EOL';
    BOLML:        Result := 'BOLML';
    EOLML:        Result := 'EOLML';
    BOUND:        Result := 'BOUND'; //###0.943
    NOTBOUND:     Result := 'NOTBOUND'; //###0.943
    ANY:          Result := 'ANY';
    ANYML:        Result := 'ANYML'; //###0.941
    ANYLETTER:    Result := 'ANYLETTER';
    NOTLETTER:    Result := 'NOTLETTER';
    ANYDIGIT:     Result := 'ANYDIGIT';
    NOTDIGIT:     Result := 'NOTDIGIT';
    ANYSPACE:     Result := 'ANYSPACE';
    NOTSPACE:     Result := 'NOTSPACE';
    ANYOF:        Result := 'ANYOF';
    ANYBUT:       Result := 'ANYBUT';
    ANYOFCI:      Result := 'ANYOF/CI';
    ANYBUTCI:     Result := 'ANYBUT/CI';
    BRANCH:       Result := 'BRANCH';
    EXACTLY:      Result := 'EXACTLY';
    EXACTLYCI:    Result := 'EXACTLY/CI';
    NOTHING:      Result := 'NOTHING';
    COMMENT:      Result := 'COMMENT';
    BACK:         Result := 'BACK';
    EEND:         Result := 'END';
    BSUBEXP:      Result := 'BSUBEXP';
    BSUBEXPCI:    Result := 'BSUBEXP/CI';
    Succ (OPEN) .. TREOp (Ord (OPEN) + NSUBEXP - 1): //###0.929
                  Result := Format ('OPEN[%d]', [ord (op) - ord (OPEN)]);
    Succ (CLOSE) .. TREOp (Ord (CLOSE) + NSUBEXP - 1): //###0.929
                  Result := Format ('CLOSE[%d]', [ord (op) - ord (CLOSE)]);
    STAR:         Result := 'STAR';
    PLUS:         Result := 'PLUS';
    BRACES:       Result := 'BRACES';
    {$IFDEF ComplexBraces}
    LOOPENTRY:    Result := 'LOOPENTRY'; //###0.925
    LOOP:         Result := 'LOOP'; //###0.925
    LOOPNG:       Result := 'LOOPNG'; //###0.940
    {$ENDIF}
    ANYOFTINYSET: Result:= 'ANYOFTINYSET';
    ANYBUTTINYSET:Result:= 'ANYBUTTINYSET';
    {$IFDEF UseSetOfChar} //###0.929
    ANYOFFULLSET: Result:= 'ANYOFFULLSET';
    {$ENDIF}
    STARNG:       Result := 'STARNG'; //###0.940
    PLUSNG:       Result := 'PLUSNG'; //###0.940
    BRACESNG:     Result := 'BRACESNG'; //###0.940
    else Error (reeDumpCorruptedOpcode);
   end; {of case op}
  Result := ':' + Result;
 end; { of function TRegExpr.DumpOp
--------------------------------------------------------------}

function TRegExpr.Dump : RegExprString;
// dump a regexp in vaguely comprehensible form
 var
  s : PRegExprChar;
  op : TREOp; // Arbitrary non-END op.
  next : PRegExprChar;
  i : Integer;
  Diff : Integer;
{$IFDEF UseSetOfChar} //###0.929
  Ch : REChar;
{$ENDIF}
begin
  if not IsProgrammOk //###0.929
   then Exit;

  op := EXACTLY;
  Result := '';
  s := FProgramm + REOpSz;
  while op <> EEND do
  begin // While that wasn't END last time...
    op := s^;
    Result := Result + Format ('%2d%s', [s - FProgramm, DumpOp (s^)]); // Where, what.
    next := regnext (s);
    if next = nil then // Next ptr.
      Result := Result + ' (0)'
    else
    begin
      if next > s then //###0.948 PWideChar subtraction workaround (see comments in Tail method for details)
        Diff := next - s
      else
        Diff := - (s - next);
      Result := Result + Format (' (%d) ', [(s - FProgramm) + Diff]);
    end;
    Inc (s, REOpSz + RENextOffSz);
    if (op = ANYOF) or (op = ANYOFCI) or (op = ANYBUT) or (op = ANYBUTCI)
        or (op = EXACTLY) or (op = EXACTLYCI) then begin
         // Literal string, where present.
         while s^ <> #0 do
         begin
           Result := Result + s^;
           Inc (s);
         end;
         Inc (s);
      end;
     if (op = ANYOFTINYSET) or (op = ANYBUTTINYSET) then
     begin
       for i := 1 to TinySetLen do
       begin
         Result := Result + s^;
         Inc (s);
       end;
     end;
     if (op = BSUBEXP) or (op = BSUBEXPCI) then
     begin
       Result := Result + ' \' + IntToStr (Ord (s^));
       Inc (s);
     end;
     {$IFDEF UseSetOfChar} //###0.929
     if op = ANYOFFULLSET then
     begin
       for Ch := #0 to #255 do
        if Ch in PSetOfREChar (s)^ then
         if Ch < ' '
          then Result := Result + '#' + IntToStr (Ord (Ch)) //###0.936
          else Result := Result + Ch;
       Inc (s, SizeOf (TSetOfREChar));
     end;
     {$ENDIF}
     if (op = BRACES) or (op = BRACESNG) then begin //###0.941
       // show min/max argument of BRACES operator
       Result := Result + Format ('{%d,%d}', [PREBracesArg (s)^, PREBracesArg (s + REBracesArgSz)^]);
       Inc (s, REBracesArgSz * 2);
      end;
     {$IFDEF ComplexBraces}
     if (op = LOOP) or (op = LOOPNG) then begin //###0.940
       Result := Result + Format (' -> (%d) {%d,%d}', [
        (s - FProgramm - (REOpSz + RENextOffSz)) + PRENextOff (s + 2 * REBracesArgSz)^,
        PREBracesArg (s)^, PREBracesArg (s + REBracesArgSz)^]);
       Inc (s, 2 * REBracesArgSz + RENextOffSz);
      end;
     {$ENDIF}
     Result := Result + #$d#$a;
   end; { of while}

  // Header fields of interest.

  if regstart <> #0
   then Result := Result + 'start ' + regstart;
  if reganch <> #0
   then Result := Result + 'anchored ';
  if regmust <> nil
   then Result := Result + 'must have ' + regmust;
  {$IFDEF UseFirstCharSet} //###0.929
  Result := Result + #$d#$a'FirstCharSet:';
  for Ch := #0 to #255 do
   if Ch in FFirstCharSet
    then begin
      if Ch < ' '
       then Result := Result + '#' + IntToStr(Ord(Ch)) //###0.948
       else Result := Result + Ch;
    end;
  {$ENDIF}
  Result := Result + #$d#$a;
 end; { of function TRegExpr.Dump
--------------------------------------------------------------}
{$ENDIF}

{$IFDEF reRealExceptionAddr}
{$OPTIMIZATION ON}
// ReturnAddr works correctly only if compiler optimization is ON
// I placed this method at very end of unit because there are no
// way to restore compiler optimization flag ...
{$ENDIF}
procedure TRegExpr.Error (AErrorID : Integer);
{$IFDEF reRealExceptionAddr}
 function ReturnAddr : pointer; //###0.938
  asm
   mov  eax,[ebp+4]
  end;
{$ENDIF}
 var
  e : ERegExpr;
 begin
  FLastError := AErrorID; // dummy stub - useless because will raise exception
  if AErrorID < 1000 // compilation error ?
   then e := ERegExpr.Create (ErrorMsg (AErrorID) // yes - show error pos
             + ' (pos ' + IntToStr (CompilerErrorPos) + ')')
   else e := ERegExpr.Create (ErrorMsg (AErrorID));
  e.ErrorCode := AErrorID;
  e.CompilerErrorPos := CompilerErrorPos;
  raise e
   {$IFDEF reRealExceptionAddr}
   At ReturnAddr; //###0.938
   {$ENDIF}
 end; { of procedure TRegExpr.Error
--------------------------------------------------------------}

(*
  PCode persistence:
   FFirstCharSet
   FProgramm, FRegsize
   regstart // -> FProgramm
   reganch // -> FProgramm
   regmust, regmlen // -> FProgramm
   FExprIsCompiled
*)

// be carefull - placed here code will be always compiled with
// compiler optimization flag

{$IFDEF FPC}
initialization
 RegExprInvertCaseFunction := TRegExpr.InvertCaseFunction;

{$ENDIF}
end.

