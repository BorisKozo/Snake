unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, ImgList, ExtCtrls, Menus, ComCtrls, IniFiles, DXInput;

type
  TForm1 = class(TForm)
    Surface: TImage;
    ImageList: TImageList;
    Timer: TTimer;
    MainMenu1: TMainMenu;
    Game1: TMenuItem;
    Level1: TMenuItem;
    About1: TMenuItem;
    New1: TMenuItem;
    LoadMaze1: TMenuItem;
    N1: TMenuItem;
    HighScore1: TMenuItem;
    N2: TMenuItem;
    Exit1: TMenuItem;
    N11: TMenuItem;
    N21: TMenuItem;
    N31: TMenuItem;
    N41: TMenuItem;
    N51: TMenuItem;
    N61: TMenuItem;
    N71: TMenuItem;
    N81: TMenuItem;
    N91: TMenuItem;
    Label1: TLabel;
    StatusBar: TStatusBar;
    OpenDialog: TOpenDialog;
    procedure FormCreate(Sender: TObject);
    procedure TimerTimer(Sender: TObject);
    procedure FormKeyPress(Sender: TObject; var Key: Char);
    procedure About1Click(Sender: TObject);
    procedure Exit1Click(Sender: TObject);
    procedure N11Click(Sender: TObject);
    procedure New1Click(Sender: TObject);
    procedure N21Click(Sender: TObject);
    procedure N31Click(Sender: TObject);
    procedure N41Click(Sender: TObject);
    procedure N51Click(Sender: TObject);
    procedure N61Click(Sender: TObject);
    procedure N71Click(Sender: TObject);
    procedure N81Click(Sender: TObject);
    procedure N91Click(Sender: TObject);
    procedure LoadMaze1Click(Sender: TObject);
    procedure HighScore1Click(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

const
  TITLE = 'Snake 2 by Boris Kozorovitzky Build 7';
  SS=8;  {The size of a square in the field}
  FX=20; {The X size of the field in squares}
  FY=9; {The Y size of the field in squares}
  PRIZE_LIMIT=5; {The number of apples you have to eat before prize appears}
  PrizeLength=150; {The time in tics a prize appears}
  HEAD_UP=6;
  HEAD_DOWN=3;
  HEAD_RIGHT=5;
  HEAD_LEFT=4;
  BODY_HORIZONTAL=1;
  BODY_VERTICAL=2;
  EMPTY_SPACE=0;
  FAT_BODY_HORIZONTAL=7;
  FAT_BODY_VERTICAL=8;
  APPLE=9;
  PRIZE1=10;
  PRIZE2=11;
  PRIZE3=12;
  PRIZE4=13;
  PRIZE5=14;
  WALL=15;
type
  Field = array [1..FX,1..FY] of integer; {The main field defenition}
var
  Form1: TForm1;
  Direction : Integer;  {6 = Up 5 = Right 3 = Down 4 = Left Coresponding to Legend}
  Head,Tail : TPoint;   {The head and the tail position}
  {Turn == 1 move of Snake's head}
  TimeToHold : Integer; {The time in turns the tail won't be removed}
  TurnLength : Integer; {The time in tics a turn lasts}
  TurnCount : Integer;  {The current count of the turn counter, each turn lasts TurnLength tics}
  Mercy : Boolean; {True iff the player got mercy pause and will die on next turn}

  AppleCount : Integer; {The number of apples eaten after prize appeared}
  PrizeCount : Integer; {The current count of the prize counter, each prize appears for PrizeLength tics}
  PrizePlace : TPoint;  {The place on the field where the prize is}
  PrizeExists : Boolean; {True iff there is a prize on the board}

  FatBodyPlace : TPoint; {The point where a fat body needs to be placed in the next turn}
  FatBodyType  : Integer; {The type of the fat body to place horizontal or vertical and EMPTY_SPACE if not need to place}

  Score : Integer; {The score of the player}
  HighScore : Integer; {The current high score}

  MainField : Field; {The main field for the game}
  ChangeField : Field; {Field where the directions in which the head went registered}

  AppDirectory : string; {The directory of the snake game}
  MazeName : string; {The maze curently loaded , some maze must be always loaded maze0 is default}
implementation

{$R *.DFM}
function MoveUp(p:TPoint):TPoint;
{Moves a point one square up}
begin
 dec(p.y);
 if p.y=0 then
  p.y:=FY;
 Result:=p;
end;

function MoveDown(p:TPoint):TPoint;
{Moves a point one square Down}
begin
 inc(p.y);
 if p.y>FY then
  p.y:=1;
 Result:=p;
end;

function MoveLeft(p:TPoint):TPoint;
{Moves a point one square left}
begin
 dec(p.x);
 if p.x=0 then
  p.x:=FX;
 Result:=p;
end;

function MoveRight(p:TPoint):TPoint;
{Moves a point one square right}
begin
 inc(p.x);
 if p.x>FX then
  p.x:=1;
 Result:=p;
end;


procedure InitField(var f:Field);
{Initializes the field to EMPTY_SPACE}
var
 i,j:Integer;
begin
 for i:=1 to FX do
  for j:=1 to FY do
   f[i,j]:=EMPTY_SPACE;
end;

procedure FieldChange(var f:Field;p:TPoint;NewVal:Integer);
{Generates the change in the field f in position p to NewVal
 and refreshes the corresponding graphics square}
var
 tx,ty:Integer;
begin
 tx:=(p.x-1)*SS+2;
 ty:=(p.y-1)*SS+2;
 with Form1.Surface.Canvas do
 begin
   Brush.Color:=clWhite;
   Brush.Style:=bsSolid;
   Pen.Color:=clwhite;
   Rectangle(tx,ty,tx+SS,ty+SS);
 end;
 f[p.x,p.y]:=NewVal;
 Form1.ImageList.Draw(Form1.Surface.Canvas,tx,ty,NewVal);
end;

function GeneratePrize(var f:Field;PrizeType:Integer):TPoint;
{Generates a prize (Apple/Critter) and places it in random place in the map,
 returns the point where the prize was generated}
var
 i,j:Integer;
 p:TPoint;
 Found:Boolean;
begin
 p.x:=random(FX)+1;
 p.y:=random(FY)+1;
 Found:=False;
 i:=1;
 j:=1;
 while (i<=FX) and (not Found) do
 begin
  while (j<=FY) and (not Found) do
  begin
   if f[p.x,p.y]=EMPTY_SPACE then
   begin
    Found:=true;
    FieldChange(f,p,PrizeType);
    Result:=p;
   end
   else
   begin
    p:=MoveUp(p);
    inc(j);
   end;
  end;
  j:=1;
  inc(i);
  p:=MoveLeft(p);
 end;
end;

procedure ReadFieldFromFile(var f:Field; FileName:string);
{Reads a standard maze file into the field f}
var
 tempFile:TextFile;
 tempString:string;
 tempPoint:TPoint;
 CommaPlace:Integer;
begin
try
 if FileExists(Filename) then
 begin
   InitField(f);
   AssignFile(tempFile,Filename);
   Reset(tempFile);
   while not EOF(tempFile) do
   begin
    Readln(tempFile,tempString);
    CommaPlace:=Pos(',',tempString);
    tempPoint.x:=StrToInt(Copy(tempString,1,CommaPlace-1));
    tempPoint.y:=StrToInt(Copy(tempString,CommaPlace+1,Length(tempString)-CommaPlace));
    if (tempPoint.x>0)   and (tempPoint.y>0) and
       (tempPoint.x<=FX) and (tempPoint.y<=FY) then
      FieldChange(f,tempPoint,WALL);
   end;
   CloseFile(tempFile);
 end
 else
  ShowMessage('File '+Filename+' does not exist');
except
 ShowMessage('There was an error opening the file');
end;
end;

procedure ClearSurface;
{Draws an empty surface}
begin
 with Form1.Surface.Canvas do
 begin
   Brush.Color:=clWhite;
   Brush.Style:=bsSolid;
   Pen.Color:=clBlack;
   Rectangle(0,0,Form1.Surface.Width,Form1.Surface.Height);
 end;
end;

procedure InitGame;
{Resets all game variables to their initial values}
begin
 ClearSurface;
 randomize;
 Direction:=HEAD_RIGHT;
 Head.x:=Trunc(FX/2);
 Head.y:=Trunc(FY/2);
 Tail:=Head;
 ReadFieldFromFile(MainField,MazeName);
 InitField(ChangeField);
 FieldChange(MainField,Head,Direction);
 TimeToHold:=4;
 TurnCount:=TurnLength;
 PrizeCount:=PrizeLength;
 AppleCount:=0;
 Score:=0;
 FatBodyType:=EMPTY_SPACE;
 GeneratePrize(MainField,APPLE);
 Form1.Level1.Enabled:=True;
 Form1.Label1.Caption:='Press SPACE to start game';
 Form1.Level1.Visible:=True;
 Form1.Timer.Enabled:=False;
 Form1.StatusBar.Panels[0].Text:='Score : '+IntToStr(Score);
 Form1.StatusBar.Panels[2].Text:='';
 Mercy:=False;
end;

procedure GameOver;
var
 f:TIniFile;
begin
 Form1.Timer.Enabled:=False;
 ShowMessage('Game Over! Your score is '+IntToStr(Score));
 if Score>HighScore then
 begin
  f:=TIniFile.Create(AppDirectory+'\snake.ini');
  HighScore:=Score;
  f.WriteString('MAIN','HighScore',IntToStr(HighScore));
  ShowMessage('You made it to the HighScore!');
 end;
 InitGame;
 Form1.Label1.Visible:=True;
end;

procedure LoadIniFile;
{Loads the ini file snake.ini}
var
 f:TIniFile;
 tempChar:Char;
 tempString:string;
begin
 if not FileExists(AppDirectory+'\snake.ini') then
 begin
  f:=TIniFile.Create(AppDirectory+'\snake.ini');
  f.WriteString('MAIN','HighScore','0');
  HighScore:=0;
  f.WriteString('MAIN','Maze','Maze0.txt');
  MazeName:=AppDirectory+'\Maze0.txt';
  f.WriteString('MAIN','Level','5');
  Form1.N51.Click;
 end
 else
 begin
  f:=TIniFile.Create(AppDirectory+'\snake.ini');
  HighScore:=StrToInt(f.ReadString('MAIN','HighScore','0'));
  MazeName:=AppDirectory+'\'+f.ReadString('MAIN','Maze','Maze0.txt');
  tempString:=f.ReadString('MAIN','Level','5');
  tempChar:=tempString[1];
  case tempChar of
   '1':Form1.N11.Click;
   '2':Form1.N21.Click;
   '3':Form1.N31.Click;
   '4':Form1.N41.Click;
   '5':Form1.N51.Click;
   '6':Form1.N61.Click;
   '7':Form1.N71.Click;
   '8':Form1.N81.Click;
   '9':Form1.N91.Click;
   else Form1.N51.Click;
  end;
 end;
end;

{FORM CREATE!}
procedure TForm1.FormCreate(Sender: TObject);
begin
 Surface.Width:=FX*SS+4;
 Surface.Height:=FY*SS+4;
 AppDirectory:=ExtractFilePath(Application.EXEName);
 OpenDialog.InitialDir:=AppDirectory;
 LoadIniFile;
 InitGame;
end;

procedure TForm1.TimerTimer(Sender: TObject);
var
 NextPoint:TPoint;
 FatFlag:Boolean; {True if fat part was already drawn and no need to draw snake body there}
begin
 if PrizeExists and (PrizeCount>0) then
 begin
  dec(PrizeCount);
  StatusBar.Panels[2].Text:='Prize : '+IntToStr(PrizeCount);
 end;

 if TurnCount=0 then
 begin
  FatFlag:=False;
  if FatBodyType<>EMPTY_SPACE then
  begin  // time to replace head with fat body part
   FieldChange(MainField,FatBodyPlace,FatBodyType);
   FatBodyType:=EMPTY_SPACE;
   FatFlag:=True; // remove the need to replace the head with fat body part
  end;

  case Direction of
   HEAD_UP:begin
            NextPoint:=MoveUp(Head);
            if MainField[NextPoint.x,NextPoint.y]=APPLE then
            begin
             FatBodyPlace:=NextPoint;
             FatBodyType:=FAT_BODY_VERTICAL;
             GeneratePrize(MainField,APPLE);
             MainField[NextPoint.x,NextPoint.y]:=EMPTY_SPACE;
             TimeToHold:=1;
             inc(Score,10-TurnLength);
             StatusBar.Panels[0].Text:='Score : '+IntToStr(Score);
             inc(AppleCount);
            end;
            if (MainField[NextPoint.x,NextPoint.y]>=PRIZE1) and
               (MainField[NextPoint.x,NextPoint.y]<=PRIZE5)then
            begin
             FatBodyPlace:=NextPoint;
             FatBodyType:=FAT_BODY_VERTICAL;
             MainField[NextPoint.x,NextPoint.y]:=EMPTY_SPACE;
             //TimeToHold:=1;
             inc(Score,PrizeCount);
             StatusBar.Panels[0].Text:='Score : '+IntToStr(Score);
             StatusBar.Panels[2].Text:='';
             PrizeExists:=False;
            end;

            if MainField[NextPoint.x,NextPoint.y]=EMPTY_SPACE then
            begin
             ChangeField[Head.x,Head.y]:=HEAD_UP;
             FieldChange(MainField,NextPoint,HEAD_UP);
             if not FatFlag then
              FieldChange(MainField,Head,BODY_VERTICAL);
             Head:=NextPoint;
            end
            else
            if not Mercy then
            begin
             Mercy:=True;
             TurnCount:=10;
             Exit;
            end
            else
            begin
             GameOver;
             Exit;
            end;
           end;
    HEAD_DOWN:begin
            NextPoint:=MoveDown(Head);
            if MainField[NextPoint.x,NextPoint.y]=APPLE then
            begin
              FatBodyPlace:=NextPoint;
              FatBodyType:=FAT_BODY_VERTICAL;
              GeneratePrize(MainField,APPLE);
              MainField[NextPoint.x,NextPoint.y]:=EMPTY_SPACE;
              inc(Score,10-TurnLength);
              StatusBar.Panels[0].Text:='Score : '+IntToStr(Score);
              TimeToHold:=1;
              inc(AppleCount);
            end;
            if (MainField[NextPoint.x,NextPoint.y]>=PRIZE1) and
               (MainField[NextPoint.x,NextPoint.y]<=PRIZE5)then
            begin
             FatBodyPlace:=NextPoint;
             FatBodyType:=FAT_BODY_VERTICAL;
             MainField[NextPoint.x,NextPoint.y]:=EMPTY_SPACE;
             //TimeToHold:=1;
             inc(Score,PrizeCount);
             StatusBar.Panels[0].Text:='Score : '+IntToStr(Score);
             StatusBar.Panels[2].Text:='';
             PrizeExists:=False;
            end;

            if MainField[NextPoint.x,NextPoint.y]=EMPTY_SPACE then
            begin
             ChangeField[Head.x,Head.y]:=HEAD_DOWN;
             FieldChange(MainField,NextPoint,HEAD_DOWN);
             if not FatFlag then
              FieldChange(MainField,Head,BODY_VERTICAL);
             Head:=NextPoint;
            end
            else
            if not Mercy then
            begin
             Mercy:=True;
             TurnCount:=10;
             Exit;
            end
            else
            begin
             GameOver;
             Exit;
            end;
           end;
    HEAD_LEFT:begin
            NextPoint:=MoveLeft(Head);
            if MainField[NextPoint.x,NextPoint.y]=APPLE then
            begin
              FatBodyPlace:=NextPoint;
              FatBodyType:=FAT_BODY_HORIZONTAL;
              GeneratePrize(MainField,APPLE);
              MainField[NextPoint.x,NextPoint.y]:=EMPTY_SPACE;
              TimeToHold:=1;
              inc(Score,10-TurnLength);
              StatusBar.Panels[0].Text:='Score : '+IntToStr(Score);
              inc(AppleCount);
            end;
            if (MainField[NextPoint.x,NextPoint.y]>=PRIZE1) and
               (MainField[NextPoint.x,NextPoint.y]<=PRIZE5)then
            begin
             FatBodyPlace:=NextPoint;
             FatBodyType:=FAT_BODY_VERTICAL;
             MainField[NextPoint.x,NextPoint.y]:=EMPTY_SPACE;
             //TimeToHold:=1;
             inc(Score,PrizeCount);
             StatusBar.Panels[0].Text:='Score : '+IntToStr(Score);
             StatusBar.Panels[2].Text:='';
             PrizeExists:=False;
            end;

            if MainField[NextPoint.x,NextPoint.y]=EMPTY_SPACE then
            begin
             ChangeField[Head.x,Head.y]:=HEAD_LEFT;
             FieldChange(MainField,NextPoint,HEAD_LEFT);
             if not FatFlag then
              FieldChange(MainField,Head,BODY_HORIZONTAL);
             Head:=NextPoint;
            end
            else
            if not Mercy then
            begin
             Mercy:=True;
             TurnCount:=10;
             Exit;
            end
            else
            begin
             GameOver;
             Exit;
            end;
           end;
    HEAD_RIGHT:begin
            NextPoint:=MoveRight(Head);
            if MainField[NextPoint.x,NextPoint.y]=APPLE then
            begin
              FatBodyPlace:=NextPoint;
              FatBodyType:=FAT_BODY_HORIZONTAL;
              GeneratePrize(MainField,APPLE);
              MainField[NextPoint.x,NextPoint.y]:=EMPTY_SPACE;
              TimeToHold:=1;
              inc(Score,10-TurnLength);
              StatusBar.Panels[0].Text:='Score : '+IntToStr(Score);
              inc(AppleCount);
            end;
            if (MainField[NextPoint.x,NextPoint.y]>=PRIZE1) and
               (MainField[NextPoint.x,NextPoint.y]<=PRIZE5)then
            begin
             FatBodyPlace:=NextPoint;
             FatBodyType:=FAT_BODY_VERTICAL;
             MainField[NextPoint.x,NextPoint.y]:=EMPTY_SPACE;
             //TimeToHold:=1;
             inc(Score,PrizeCount);
             StatusBar.Panels[0].Text:='Score : '+IntToStr(Score);
             StatusBar.Panels[2].Text:='';
             PrizeExists:=False;
            end;

            if MainField[NextPoint.x,NextPoint.y]=EMPTY_SPACE then
            begin
             ChangeField[Head.x,Head.y]:=HEAD_RIGHT;
             FieldChange(MainField,NextPoint,HEAD_RIGHT);
             if not FatFlag then
              FieldChange(MainField,Head,BODY_HORIZONTAL);
             Head:=NextPoint;
            end
            else
            if not Mercy then
            begin
             Mercy:=True;
             TurnCount:=10;
             Exit;
            end
            else
            begin
             GameOver;
             Exit;
            end;
           end;

  end;

  if (AppleCount=PRIZE_LIMIT) then
  begin
    AppleCount:=0;
    PrizePlace:=GeneratePrize(MainField,PRIZE1+random(5));
    PrizeExists:=True;
    PrizeCount:=PrizeLength;
  end;
  if PrizeExists and (PrizeCount=0) then
  begin
    FieldChange(MainField,PrizePlace,EMPTY_SPACE);
    PrizeExists:=False;
    StatusBar.Panels[2].Text:='';
    PrizeCount:=PrizeLength;
  end;
  if TimeToHold=0 then
  begin
    NextPoint:=Tail;
    case ChangeField[Tail.x,Tail.y] of
     HEAD_UP    : Tail:=MoveUp(Tail);
     HEAD_DOWN  : Tail:=MoveDown(Tail);
     HEAD_LEFT  : Tail:=MoveLeft(Tail);
     HEAD_RIGHT : Tail:=MoveRight(Tail);
    end;
    ChangeField[NextPoint.x,NextPoint.y]:=EMPTY_SPACE;
    FieldChange(MainField,NextPoint,EMPTY_SPACE);
   end
  else
   dec(TimeToHold);
  TurnCount:=TurnLength;
  Mercy:=False;
 end
 else
  dec(TurnCount);

end;
procedure TForm1.FormKeyPress(Sender: TObject; var Key: Char);
var
 CurrentDirection:Integer;
begin
 CurrentDirection:=MainField[Head.x,Head.y];
 case key of
 '8':if (CurrentDirection=HEAD_LEFT) or (CurrentDirection=HEAD_RIGHT) then
       Direction:=HEAD_UP;
 '4':if (CurrentDirection=HEAD_UP) or (CurrentDirection=HEAD_DOWN) then
       Direction:=HEAD_LEFT;
 '2','5':if (CurrentDirection=HEAD_LEFT) or (CurrentDirection=HEAD_RIGHT) then
       Direction:=HEAD_DOWN;
 '6':if (CurrentDirection=HEAD_UP) or (CurrentDirection=HEAD_DOWN) then
       Direction:=HEAD_RIGHT;
 '7':if (CurrentDirection=HEAD_UP) or (CurrentDirection=HEAD_DOWN) then
      Direction:=HEAD_LEFT
     else
     if (CurrentDirection=HEAD_LEFT) or (CurrentDirection=HEAD_RIGHT) then
      Direction:=HEAD_UP;
 '9':if (CurrentDirection=HEAD_UP) or (CurrentDirection=HEAD_DOWN) then
      Direction:=HEAD_RIGHT
     else
     if (CurrentDirection=HEAD_LEFT) or (CurrentDirection=HEAD_RIGHT) then
      Direction:=HEAD_UP;
 '1':if (CurrentDirection=HEAD_UP) or (CurrentDirection=HEAD_DOWN) then
      Direction:=HEAD_LEFT
     else
     if (CurrentDirection=HEAD_LEFT) or (CurrentDirection=HEAD_RIGHT) then
      Direction:=HEAD_DOWN;
 '3':if (CurrentDirection=HEAD_UP) or (CurrentDirection=HEAD_DOWN) then
      Direction:=HEAD_RIGHT
     else
     if (CurrentDirection=HEAD_LEFT) or (CurrentDirection=HEAD_RIGHT) then
      Direction:=HEAD_DOWN;

 ' ':if Timer.Enabled then
     begin
      Label1.Caption:='Press SPACE to continue';
      Label1.Visible:=True;
      Timer.Enabled:=False;
     end
     else
     begin
        Label1.visible:=False;
        Level1.Enabled:=False;
        Timer.Enabled:=True;
     end;
 end;

end;

procedure TForm1.About1Click(Sender: TObject);
begin
 ShowMessage(TITLE);
end;

procedure TForm1.Exit1Click(Sender: TObject);
begin
 Close;
end;

procedure TForm1.New1Click(Sender: TObject);
begin
 InitGame;
end;

procedure SaveLevelNumber(Number:Integer);
var
 f:TIniFile;
begin
 f:=TIniFile.Create(AppDirectory+'\snake.ini');
 f.WriteString('MAIN','Level',IntToStr(Number));
end;

procedure TForm1.N11Click(Sender: TObject);
begin
 N11.Checked:=True;
 N21.Checked:=False;
 N31.Checked:=False;
 N41.Checked:=False;
 N51.Checked:=False;
 N61.Checked:=False;
 N71.Checked:=False;
 N81.Checked:=False;
 N91.Checked:=False;
 TurnLength:=9;
 StatusBar.Panels[1].Text:='Level : 1';
 SaveLevelNumber(1);
 InitGame;
end;



procedure TForm1.N21Click(Sender: TObject);
begin
 N11.Checked:=False;
 N21.Checked:=True;
 N31.Checked:=False;
 N41.Checked:=False;
 N51.Checked:=False;
 N61.Checked:=False;
 N71.Checked:=False;
 N81.Checked:=False;
 N91.Checked:=False;
 TurnLength:=8;
 StatusBar.Panels[1].Text:='Level : 2';
 SaveLevelNumber(2);
 InitGame;
end;

procedure TForm1.N31Click(Sender: TObject);
begin
 N11.Checked:=False;
 N21.Checked:=False;
 N31.Checked:=True;
 N41.Checked:=False;
 N51.Checked:=False;
 N61.Checked:=False;
 N71.Checked:=False;
 N81.Checked:=False;
 N91.Checked:=False;
 TurnLength:=7;
 StatusBar.Panels[1].Text:='Level : 3';
 SaveLevelNumber(3);
 InitGame;
end;

procedure TForm1.N41Click(Sender: TObject);
begin
 N11.Checked:=False;
 N21.Checked:=False;
 N31.Checked:=False;
 N41.Checked:=True;
 N51.Checked:=False;
 N61.Checked:=False;
 N71.Checked:=False;
 N81.Checked:=False;
 N91.Checked:=False;
 TurnLength:=6;
 StatusBar.Panels[1].Text:='Level : 4';
 SaveLevelNumber(4);
 InitGame;
end;

procedure TForm1.N51Click(Sender: TObject);
begin
 N11.Checked:=False;
 N21.Checked:=False;
 N31.Checked:=False;
 N41.Checked:=False;
 N51.Checked:=True;
 N61.Checked:=False;
 N71.Checked:=False;
 N81.Checked:=False;
 N91.Checked:=False;
 TurnLength:=5;
 StatusBar.Panels[1].Text:='Level : 5';
 SaveLevelNumber(5);
 InitGame;
end;


procedure TForm1.N61Click(Sender: TObject);
begin
 N11.Checked:=False;
 N21.Checked:=False;
 N31.Checked:=False;
 N41.Checked:=False;
 N51.Checked:=False;
 N61.Checked:=True;
 N71.Checked:=False;
 N81.Checked:=False;
 N91.Checked:=False;
 TurnLength:=4;
 StatusBar.Panels[1].Text:='Level : 6';
 SaveLevelNumber(6);
 InitGame;
end;

procedure TForm1.N71Click(Sender: TObject);
begin
 N11.Checked:=False;
 N21.Checked:=False;
 N31.Checked:=False;
 N41.Checked:=False;
 N51.Checked:=False;
 N61.Checked:=False;
 N71.Checked:=True;
 N81.Checked:=False;
 N91.Checked:=False;
 TurnLength:=3;
 StatusBar.Panels[1].Text:='Level : 7';
 SaveLevelNumber(7);
 InitGame;
end;

procedure TForm1.N81Click(Sender: TObject);
begin
 N11.Checked:=False;
 N21.Checked:=False;
 N31.Checked:=False;
 N41.Checked:=False;
 N51.Checked:=False;
 N61.Checked:=False;
 N71.Checked:=False;
 N81.Checked:=True;
 N91.Checked:=False;
 TurnLength:=2;
 StatusBar.Panels[1].Text:='Level : 8';
 SaveLevelNumber(8);
 InitGame;
end;

procedure TForm1.N91Click(Sender: TObject);
begin
 N11.Checked:=False;
 N21.Checked:=False;
 N31.Checked:=False;
 N41.Checked:=False;
 N51.Checked:=False;
 N61.Checked:=False;
 N71.Checked:=False;
 N81.Checked:=False;
 N91.Checked:=True;
 TurnLength:=1;
 StatusBar.Panels[1].Text:='Level : 9';
 SaveLevelNumber(9);
 InitGame;
end;

procedure TForm1.LoadMaze1Click(Sender: TObject);
var
 f:TIniFile;
begin
 Timer.Enabled:=False;
 if OpenDialog.Execute then
 begin
  MazeName:=OpenDialog.FileName;
  f:=TIniFile.Create(AppDirectory+'\snake.ini');
  f.WriteString('MAIN','Maze',ExtractFileName(OpenDialog.Filename));
 end;
 InitGame;
end;

procedure TForm1.HighScore1Click(Sender: TObject);
begin
 ShowMessage('The HighScore is '+IntToStr(HighScore));
end;

procedure TForm1.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
var
 CurrentDirection:Integer;
begin
 CurrentDirection:=MainField[Head.x,Head.y];
 case key of
 VK_UP:if (CurrentDirection=HEAD_LEFT) or (CurrentDirection=HEAD_RIGHT) then
       Direction:=HEAD_UP;
 VK_LEFT:if (CurrentDirection=HEAD_UP) or (CurrentDirection=HEAD_DOWN) then
       Direction:=HEAD_LEFT;
 VK_DOWN:if (CurrentDirection=HEAD_LEFT) or (CurrentDirection=HEAD_RIGHT) then
       Direction:=HEAD_DOWN;
 VK_RIGHT:if (CurrentDirection=HEAD_UP) or (CurrentDirection=HEAD_DOWN) then
       Direction:=HEAD_RIGHT;

 end;
end;

end.
