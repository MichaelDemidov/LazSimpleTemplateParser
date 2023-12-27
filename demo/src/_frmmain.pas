unit _frmMain;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  IpHtml, simpletemplateparser;

type

  { TfrmMain }

  TfrmMain = class(TForm)
    btnLoadNews: TButton;
    htmlMain: TIpHtmlPanel;
    pnlToolbar: TPanel;
    procedure btnLoadNewsClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  private
    FParser: TSimpleTemplateParser;

    procedure PrepareHTML;
    procedure UpdateHTML;
  end;

var
  frmMain: TfrmMain;

implementation

{$R *.lfm}

{ TfrmMain }

procedure TfrmMain.FormCreate(Sender: TObject);
begin
  Caption := Application.Title;

  try
    FParser := TSimpleTemplateParser.CreateFromFile(ChangeFileExt
      (Application.ExeName, '.stp'));
  except
    FreeAndNil(FParser);
    Application.Terminate;
    Exit;
  end;

  PrepareHTML;
  UpdateHTML;
end;

procedure TfrmMain.btnLoadNewsClick(Sender: TObject);
begin
  FParser.TextFiles['news'] := ExtractFilePath(Application.ExeName) + 'news.txt';
  FParser.Parse;

  UpdateHTML;
end;

procedure TfrmMain.FormDestroy(Sender: TObject);
begin
  FParser.Free;
end;

procedure TfrmMain.PrepareHTML;

  function ColorToHTML(C: TColor): string;
  begin
    C := ColorToRGB(C);
    Result := IntToHex(Red(C), 2) + IntToHex(Green(C), 2) + IntToHex(Blue(C),
      2);
  end;

var
  HtmlFont: TFont;
  FontData: TFontData;
  I: Integer;
const
  FontStyles: array[Boolean] of string = ('normal', 'italic');
  FontWeights: array[Boolean] of string = ('normal', 'bold');
begin
  HtmlFont := Screen.HintFont;
  FontData := GetFontData(HtmlFont.Handle);

  FParser.Variables['FONT_NAME'] := FontData.Name;
  FParser.Variables['FONT_STYLE'] := FontStyles[fsItalic in FontData.Style];
  FParser.Variables['FONT_WEIGHT'] := FontWeights[fsItalic in FontData.Style];
  I := Round((Abs(FontData.Height) * 72 / HtmlFont.PixelsPerInch));
  FParser.Variables['FONT_SIZE'] := IntToStr(I);

  FParser.Variables['BACK_COLOR'] := ColorToHTML(clInfoBk);
  FParser.Variables['FONT_COLOR'] := ColorToHTML(clInfoText);
end;

procedure TfrmMain.UpdateHTML;
var
  StrHelpStream: TStringStream;
  IPHTML: TIPHTML;
begin
  FParser.CreateContent;

  StrHelpStream := TStringStream.Create(FParser.Content);
  try
    IPHTML := TIPHTML.Create;
    IPHTML.LoadFromStream(StrHelpStream);
    htmlMain.SetHtml(IPHTML);
  finally
    FreeAndNil(StrHelpStream);
  end;
end;

end.

