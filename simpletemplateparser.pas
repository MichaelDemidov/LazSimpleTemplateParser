unit simpletemplateparser;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Contnrs, db;

type
  { TSimpleTemplateParser }

  TSimpleTemplateParser = class
  private
    // the template content as a string
    FTemplate: string;

    // the content after inserting the data into the template (see the
    // CreateContent() procedure below)
    FContent: string;

    // true after the Parse() procedure call
    FParsed: Boolean;

    // "global" variables, see below
    FVariables: TStringList;

    // text files
    FTextFiles: TStringList;

    // template entities, filled by Parse() procedure
    FTemplateEntitiesList: TObjectList;

    // dataset lists: FScrollDatasets is the list of the datasets with enabled
    // BeforeScroll/AfterScroll; FNoScrollDatasets is the list of the datasets
    // with disabled
    FScrollDatasets,
    FNoScrollDatasets: TComponentList;

    // property getters and setters
    function GetVariable(Name: string): string;
    procedure SetVariable(Name, Value: string);
    function GetTextFile(Name: string): string;
    procedure SetTextFile(Name, Path: string);

    // load the text files contents
    procedure LoadTexts;

    // clean the text files contents
    procedure ClearTexts;
  public
    // constuctor and destuctor
    constructor Create(ATemplate: string);
    constructor CreateFromFile(AFileName: string);
    destructor Destroy; override;

    // add the dataset into the list
    procedure AddDataset(Dataset: TDataset; DisableScrollEvents: Boolean =
      True);

    // remove the dataset from the list
    procedure RemoveDataset(Dataset: TDataset);

    // load the template string from the stream
    procedure LoadFromStream(AStream: TStream);

    // load the template string from the text file
    procedure LoadFromFile(AFileName: string);

    // prepare the inner structure (optional, called from CreateContent)
    procedure Parse;

    // insert the previously stored constants, variables, dataset data into
    // the Content string
    procedure CreateContent(AVarList: TStrings = nil);

    // the content after inserting the data into the template (see the
    // CreateContent() procedure above)
    property Content: string read FContent;

    // "global" variables
    property Variables[Name: string]: string read GetVariable write SetVariable;

    // text  files
    property TextFiles[Name: string]: string read GetTextFile write SetTextFile;
  end;

// template syntax elements
const
  CBracketVarLeft = '{{';
  CBracketVarRight = '}}';
  CBracketKeywordLeft = '{%';
  CBracketKeywordRight = '%}';
  CEmptyDelimiter = '??';
  CKeywordIf = 'if';
  CKeywordElse = 'else';
  CKeywordEndif = 'endif';
  CKeywordFor = 'for';
  CKeywordEndfor = 'endfor';

implementation

{$i textfilecontents.inc }

// there is a bunch of small classes--I moved them into the separate file
{$i parserentities.inc}

{ TSimpleTemplateParser }

constructor TSimpleTemplateParser.Create(ATemplate: string);
begin
  FTemplate := ATemplate;
  FParsed := False;
  FVariables := TStringList.Create;
  FTextFiles := TStringList.Create;
  FTemplateEntitiesList := TObjectList.Create;
  FScrollDatasets := TComponentList.Create(False);
  FNoScrollDatasets := TComponentList.Create(False);
end;

constructor TSimpleTemplateParser.CreateFromFile(AFileName: string);
begin
  Create('');
  LoadFromFile(AFileName);
end;

destructor TSimpleTemplateParser.Destroy;
begin
  FreeAndNil(FTemplateEntitiesList);
  FreeAndNil(FVariables);
  if FTextFiles.Count > 0 then
    ClearTexts;
  FreeAndNil(FTextFiles);
  FreeAndNil(FScrollDatasets);
  FreeAndNil(FNoScrollDatasets);
  inherited Destroy;
end;

procedure TSimpleTemplateParser.LoadFromFile(AFileName: string);
var
  StrStream: TStringStream;
begin
  StrStream := TStringStream.Create;
  try
    StrStream.LoadFromFile(AFileName);
    FTemplate := StrStream.DataString;
    FreeAndNil(StrStream);
  except
    FreeAndNil(StrStream);
    raise;
  end;
end;

procedure TSimpleTemplateParser.LoadFromStream(AStream: TStream);
var
  StrStream: TStringStream;
begin
  if Assigned(AStream) then
  begin
    if AStream is TStringStream then
      FTemplate := (AStream as TStringStream).DataString
    else
    begin
      AStream.Position := 0;
      StrStream := TStringStream.Create;
      try
        StrStream.LoadFromStream(AStream);
        FTemplate := StrStream.DataString;
        FreeAndNil(StrStream);
      except
        FreeAndNil(StrStream);
        raise;
      end;
    end;
  end;
end;

procedure TSimpleTemplateParser.LoadTexts;
var
  I: Integer;
  FileName: string;
  FileContent: TTextFileContents;
begin
  ClearTexts;
  for I := 0 to FTextFiles.Count - 1 do
  begin
    FileName := FTextFiles.ValueFromIndex[I];
    if FileExists(FileName) then
    begin
      FileContent := TTextFileContents.Create(FileName);
      FTextFiles.Objects[I] := FileContent;
    end;
  end;
end;

procedure TSimpleTemplateParser.ClearTexts;
var
  I: Integer;
begin
  for I := 0 to FTextFiles.Count - 1 do
    if Assigned(FTextFiles.Objects[I]) then
    begin
      FTextFiles.Objects[I].Free;
      FTextFiles.Objects[I] := nil;
    end;
end;

procedure TSimpleTemplateParser.AddDataset(Dataset: TDataset;
  DisableScrollEvents: Boolean = True);
var
  I: Integer;
begin
  if DisableScrollEvents then
  begin
    I := FScrollDatasets.IndexOf(Dataset);
    if I >= 0 then
      FScrollDatasets.Delete(I);
    if FNoScrollDatasets.IndexOf(Dataset) < 0 then
      FNoScrollDatasets.Add(Dataset);
  end
  else
  begin
    I := FNoScrollDatasets.IndexOf(Dataset);
    if I >= 0 then
      FNoScrollDatasets.Delete(I);
    if FScrollDatasets.IndexOf(Dataset) < 0 then
      FScrollDatasets.Add(Dataset);
  end;
end;

procedure TSimpleTemplateParser.RemoveDataset(Dataset: TDataset);
var
  I: Integer;
begin
  I := FNoScrollDatasets.IndexOf(Dataset);
  if I >= 0 then
    FNoScrollDatasets.Delete(I)
  else
  begin
    I := FScrollDatasets.IndexOf(Dataset);
    if I >= 0 then
      FScrollDatasets.Delete(I);
  end;
end;

function TSimpleTemplateParser.GetVariable(Name: string): string;
begin
  Result := FVariables.Values[Name];
end;

procedure TSimpleTemplateParser.SetVariable(Name, Value: string);
begin
  FVariables.Values[Name] := Value;
end;

function TSimpleTemplateParser.GetTextFile(Name: string): string;
begin
  Result := FTextFiles.Values[Name];
end;

procedure TSimpleTemplateParser.SetTextFile(Name, Path: string);
begin
  FTextFiles.Values[Name] := Path;
end;

procedure TSimpleTemplateParser.Parse;

  function FindDataset(AName: string):
    TDataSet;
  var
    I: Integer;
  begin
    Result := nil;
    for I := 0 to FNoScrollDatasets.Count - 1 do
      if SameText(FNoScrollDatasets[I].Name, AName) then
      begin
        Result := FNoScrollDatasets[I] as TDataset;
        Break;
      end;
    if not Assigned(Result) then
      for I := 0 to FScrollDatasets.Count - 1 do
        if SameText(FScrollDatasets[I].Name, AName) then
        begin
          Result := FScrollDatasets[I] as TDataset;
          Break;
        end;
  end;

  function FindField(AName: string): TField;
  var
    I: Integer;
    DS: TDataset;
  begin
    Result := nil;

    I := Pos('.', AName);
    if I > 0 then
    begin
      DS := FindDataset(Trim(Copy(AName, 1, I - 1)));
      if Assigned(DS) then
        Result := DS.FindField(Trim(Copy(AName, I + 1, Length(AName) - 1)));
    end;
  end;

  function CheckKeyWord(Str, Keyword: string): Boolean;
  const
    Spaces = [' ', #13, #10, #9];
  begin
    Result := (Str = Keyword)
      or (Length(Str) > Length(Keyword))
        and (LowerCase(LeftStr(Str, Length(Keyword))) = Keyword)
        and (Str[Length(Keyword) + 1] in Spaces);
  end;

  function GetTopItem(Stack: TObjectStack; ObjType: TBasicEntityClass):
    TBasicEntity;
  begin
    Result := nil;
    if Stack.Count > 0 then
    begin
      repeat
        Result := Stack.Peek as TBasicEntity;
        if not (Result is ObjType) then
          Stack.Pop;
      until
        not Assigned(Result) or (Result is ObjType);
    end;
  end;

var
  I: Integer;
  S: string;
  DS: TDataSet;
  Fld: TField;
  List: TObjectList;
  Stack: TObjectStack;
  Entity: TBasicEntity;
  LVarPos: Integer;
  LLastPos: Integer;
  LKWordPos: Integer;
begin
  S := '';
  LLastPos := 1;
  List := FTemplateEntitiesList;
  List.Clear;
  Stack := TObjectStack.Create;
  Entity := nil;

  repeat
    LVarPos := Pos(CBracketVarLeft, FTemplate, LLastPos);
    LKWordPos := Pos(CBracketKeywordLeft, FTemplate, LLastPos);

    if (LVarPos = 0) and (LKWordPos = 0) then
      Break;

    // variable first: {{VAR}}, {{DataSet.Field}}, {{DataSet.Field??EmptyValue}}
    if (LVarPos > 0) and ((LVarPos < LKWordPos) or (LKWordPos = 0)) then
    begin
      // last position
      if LLastPos < LVarPos then
      begin
        Entity := TPlainTextEntity.Create(List);
        (Entity as TPlainTextEntity).Content := Copy(FTemplate, LLastPos, LVarPos -
          LLastPos);
        Entity := nil;
      end;

      I := Pos(CBracketVarRight, FTemplate, LVarPos);
      if I > 0 then
      begin
        // {{QueryName.FIELD??empty value}} or {{QueryName.FIELD}} or
        // {{VAR??empty value}} or {{VAR}}
        LLastPos := I + Length(CBracketVarRight);
        // S = 'QueryName.FIELD??empty value', etc, i.e. the curly brackets are
        // removed
        S := Trim(Copy(FTemplate, LVarPos + Length(CBracketVarLeft), I - LVarPos
          - Length(CBracketVarLeft) - Length(CBracketVarRight) + 2));
        I := Pos(CEmptyDelimiter, S);
        // {{VAR} or {{DataSet.Field}}
        if I = 0 then
        begin
          I := Pos('.', S);
          // {{VAR}}
          if I = 0 then
          begin
            Entity := TVarEntity.Create(List);
            (Entity as TVarEntity).Name := Trim(S);
            Entity := nil;
          end else
          // {{DataSet.Field}}
          begin
            Fld := FindField(S);
            if Assigned(Fld) then
            begin
              Entity := TDataFieldEntity.Create(List);
              (Entity as TDataFieldEntity).Field := Fld;
              Entity := nil;
            end;
          end;
        end
        else
        // {{DataSet.Field??EmptyValue}}
        begin
          Fld := FindField(Trim(Copy(S, 1, I - 1)));
          if Assigned(Fld) then
          begin
            Entity := TDataFieldEntity.Create(List);
            (Entity as TDataFieldEntity).Field := Fld;
            (Entity as TDataFieldEntity).IfEmptyField := Trim(Copy(S, I +
              Length(CEmptyDelimiter), Length(S) - I - Length(CEmptyDelimiter) +
              1));
            Entity := nil;
          end;
        end;
      end;
    end
    // keyword first: {%if VAR%}, {%if DataSource%}, {%if DataSource.Field%},
    // {%for DataSource%}
    else
    begin
      // last position
      if LLastPos < LKWordPos then
      begin
        Entity := TPlainTextEntity.Create(List);
        (Entity as TPlainTextEntity).Content := Copy(FTemplate, LLastPos, LKWordPos -
          LLastPos);
        Entity := nil;
      end;

      I := Pos(CBracketKeywordRight, FTemplate, LKWordPos);
      if I > 0 then
      begin
        LLastPos := I + Length(CBracketKeywordRight);
        // S = 'if ...' or 'for ...'
        S := Trim(Copy(FTemplate, LKWordPos + Length(CBracketKeywordLeft), I -
          LKWordPos - Length(CBracketKeywordLeft) -
          Length(CBracketKeywordRight) + 2));
        // {%if ... %}
        // S = 'if VAR', 'if DataSet', or 'if DataSet.Field'
        if CheckKeyWord(S, CKeywordIf) then
        begin
          Delete(S, 1, Length(CKeywordIf));
          // S = 'VAR', 'DataSet', or 'DataSet.Field'
          I := Pos('.', S);
          // VAR or DataSet
          if I = 0 then
          begin
            S := Trim(S);
            DS := FindDataset(S);
            // DataSet
            if Assigned(DS) then
            begin
              Entity := TIfDatasetEntity.Create(List);
              (Entity as TIfDatasetEntity).Dataset := DS;
            end
            else
            // VAR
            begin
              Entity := TIfVarEntity.Create(List);
              (Entity as TIfVarEntity).Name := S;
            end;
          end else
          // DataSet.Field
          begin
            Fld := FindField(S);
            if Assigned(Fld) then
            begin
              Entity := TIfFieldEntity.Create(List);
              (Entity as TIfFieldEntity).Field := Fld;
            end;
          end;
          // go to the nested level
          if Assigned(Entity) and (Entity is TBasicIfEntity) then
          begin
            Stack.Push(Entity);
            List := (Entity as TBasicIfEntity).IfActions;
            Entity := nil;
          end;
        end
        // {%else%}
        else if CheckKeyWord(S, CKeywordElse) then
        begin
          Entity := GetTopItem(Stack, TBasicIfEntity);
          if Assigned(Entity) then
          begin
            List := (Entity as TBasicIfEntity).IfActionsElse;
            Entity := nil;
          end;
        end
        // {%endif%}
        else if CheckKeyWord(S, CKeywordEndif) then
        begin
          Entity := GetTopItem(Stack, TBasicIfEntity);
          if Assigned(Entity) then
          begin
            Stack.Pop;
            List := Entity.Owner;
            Entity := nil;
          end
          else
            List := FTemplateEntitiesList;
        end
        // {%for ... %}
        else if CheckKeyWord(S, CKeywordFor) then
        begin
          Delete(S, 1, Length(CKeywordFor));
          // S = 'DataSet' / 'TextFile'
          S := Trim(S);
          DS := FindDataset(S);
          if Assigned(DS) then // dataset
          begin
            Entity := TForDatasetEntity.Create(List);
            (Entity as TForDatasetEntity).Dataset := DS;
            Stack.Push(Entity);
            List := (Entity as TForDatasetEntity).Actions;
            Entity := nil;
          end
          else
          begin // text file
            I := FTextFiles.IndexOfName(S);
            if I >= 0 then
            begin
              Entity := TForTextFileEntity.Create(List);
              (Entity as TForTextFileEntity).Name := S;
              Stack.Push(Entity);
              List := (Entity as TForTextFileEntity).Actions;
              Entity := nil;
            end;
          end;
        end
        // {%endfor%}
        else if CheckKeyWord(S, CKeywordEndfor) then
        begin
          Entity := GetTopItem(Stack, TBasicForEntity);
          if Assigned(Entity) then
          begin
            Stack.Pop;
            List := Entity.Owner;
            Entity := nil;
          end
          else
            List := FTemplateEntitiesList;
        end;
      end;
    end;
  until
    (LVarPos = 0) and (LKWordPos = 0);

  // either remains after successful parsing or nothing found (plain text)
  if LLastPos < Length(FTEmplate) then
  begin
    Entity := TPlainTextEntity.Create(List);
    S := Copy(FTemplate, LLastPos, Length(FTemplate) - LLastPos + 1);
    (Entity as TPlainTextEntity).Content := S;
  end;

  FreeAndNil(Stack);
  FParsed := True;
end;

procedure TSimpleTemplateParser.CreateContent(AVarList: TStrings = nil);

  function TranslateEntity(Entity: TBasicEntity): string; forward;

  function TranslateList(List: TObjectList): string;
  var
    I: Integer;
  begin
    Result := '';
    for I := 0 to List.Count - 1 do
      Result := Result + TranslateEntity(List[I] as TBasicEntity);
  end;

  function TranslateEntity(Entity: TBasicEntity): string;
  var
    Fld: TField;
    DS: TDataset;
    TextFC: TTextFileContents;
    R: Integer;
    S: string;
    SaveBeforeScroll, SaveAfterScroll: TDatasetNotifyEvent;
  begin
    Result := '';
    { plain text }
    if Entity is TPlainTextEntity then
      Result := (Entity as TPlainTextEntity).Content
    { variable / text file line }
    else if Entity is TVarEntity then
    begin
      R := FVariables.IndexOfName((Entity as TVarEntity).Name);
      if R >= 0 then
        Result := FVariables.ValueFromIndex[R]
      else
        if Assigned(AVarList) then
          Result := AVarList.Values[(Entity as TVarEntity).Name]
        else
        begin
          Result := '';
          R := FTextFiles.IndexOfName((Entity as TVarEntity).Name);
          if (R >= 0) and Assigned(FTextFiles.Objects[R]) then
          begin
            TextFC := FTextFiles.Objects[R] as TTextFileContents;
            Result := TextFC.NextLine;
          end;
        end;
    end
    { data field }
    else if Entity is TDataFieldEntity then
    begin
      Fld := (Entity as TDataFieldEntity).Field;
      if not Assigned(Fld) or Fld.IsNull then
        Result := (Entity as TDataFieldEntity).IfEmptyField
      else
      begin
        if Fld is TBlobField then
        begin
          if Assigned(Fld.OnGetText) then
            Fld.OnGetText(Fld, Result, True)
          else
            Result := Fld.AsString
        end
        else
          Result := Fld.DisplayText;
      end;
    end
    { if variable }
    else if Entity is TIfVarEntity then
    begin
      R := FVariables.IndexOfName((Entity as TIfVarEntity).Name);
      if R >= 0 then
        S := FVariables.ValueFromIndex[R]
      else
        if Assigned(AVarList) then
          S := AVarList.Values[(Entity as TIfVarEntity).Name]
        else
        begin
          S := '';
          R := FTextFiles.IndexOfName((Entity as TIfVarEntity).Name);
          if R >= 0 then
            S := FTextFiles.ValueFromIndex[R];
        end;

      if S = '' then
        Result := TranslateList((Entity as TIfVarEntity).IfActionsElse)
      else
        Result := TranslateList((Entity as TIfVarEntity).IfActions);
    end
    { if dataset }
    else if Entity is TIfDatasetEntity then
    begin
      DS := (Entity as TIfDatasetEntity).Dataset;
      if not Assigned(DS) or DS.IsEmpty then
        Result := TranslateList((Entity as TIfDatasetEntity).IfActionsElse)
      else
        Result := TranslateList((Entity as TIfDatasetEntity).IfActions);
    end
    { if field }
    else if Entity is TIfFieldEntity then
    begin
      Fld := (Entity as TIfFieldEntity).Field;
      if not Assigned(Fld) or Fld.IsNull then
        Result := TranslateList((Entity as TIfFieldEntity).IfActionsElse)
      else
        Result := TranslateList((Entity as TIfFieldEntity).IfActions);
    end
    { for text file }
    else if Entity is TForTextFileEntity then
    begin
      R := FTextFiles.IndexOfName((Entity as TForTextFileEntity).Name);

      if (R >= 0) and Assigned(FTextFiles.Objects[R]) then
      begin
        TextFC := FTextFiles.Objects[R] as TTextFileContents;
        if TextFC.Contents.Count > 0 then
        begin
          TextFC.CurrectLine := 0;

          while TextFC.CurrectLine <= TextFC.Contents.Count - 1 do
          begin
            R := TextFC.CurrectLine;
            Result := Result + TranslateList((Entity as
              TForTextFileEntity).Actions);
            if R = TextFC.CurrectLine then
              TextFC.CurrectLine := TextFC.CurrectLine + 1;
          end
        end;
      end;
    end
    { for dataset }
    else if Entity is TForDatasetEntity then
    begin
      DS := (Entity as TForDatasetEntity).Dataset;
      if Assigned(DS) and not DS.IsEmpty then
      begin
        DS.DisableControls;
        SaveBeforeScroll := nil;
        SaveAfterScroll := nil;

        if FNoScrollDatasets.IndexOf(DS) >= 0 then
        begin
          SaveBeforeScroll := DS.BeforeScroll;
          SaveAfterScroll := DS.AfterScroll;
        end;

        R := DS.RecNo;
        while not DS.Eof do
        begin
          Result := Result + TranslateList((Entity as
            TForDatasetEntity).Actions);
          DS.Next;
        end;
        DS.RecNo := R;

        if Assigned(SaveBeforeScroll) then
          DS.BeforeScroll := SaveBeforeScroll;
        if Assigned(SaveAfterScroll) then
          DS.AfterScroll := SaveAfterScroll;

        DS.EnableControls;
      end;
    end;
  end;

begin
  if not FParsed then
    Parse;

  FContent := '';

  LoadTexts;

  if FTemplateEntitiesList.Count = 0 then
    FContent := FTemplate
  else
    FContent := TranslateList(FTemplateEntitiesList);
end;

end.

