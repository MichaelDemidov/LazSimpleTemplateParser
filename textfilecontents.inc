type
  { TTextFileContents }

  TTextFileContents = class
  strict private
    FContents: TStrings;
    FCurrentLine: Integer;

    function GetNextLine: string;
  public
    // file contents
    property Contents: TStrings read FContents;

    // current line number
    property CurrectLine: Integer read FCurrentLine write FCurrentLine;

    // get the next non-empty line and increase the CurrectLine counter
    property NextLine: string read GetNextLine;

    // constuctor and destuctor
    constructor Create(AFilePath: string);
    destructor Destroy; override;
  end;

constructor TTextFileContents.Create(AFilePath: string);
begin
  FContents := TStringList.Create;
  FContents.LoadFromFile(AFilePath);
  FCurrentLine := -1;
end;

destructor TTextFileContents.Destroy;
begin
  FreeAndNil(FContents);
  inherited Destroy;
end;

function TTextFileContents.GetNextLine: string;
begin
  Result := '';
  if (FContents.Count > 0) and (FCurrentLine < FContents.Count) then
  begin
    repeat
      Result := FContents[FCurrentLine];
      FCurrentLine := FCurrentLine + 1;
    until
      (FCurrentLine >= FContents.Count) or (Result <> '')
  end;
end;
