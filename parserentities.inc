type
  { --------------------- GENERIC ITEM (COMMON ANCESTOR) --------------------- }
  TBasicEntity = class(TObject)
  private
    FOwner: TObjectList;
  public
    constructor Create(AOwner: TObjectList); virtual;
    destructor Destroy; override;

    property Owner: TObjectList read FOwner;
  end;

  TBasicEntityClass = class of TBasicEntity;

  { ------------------------------- PLAIN TEXT ------------------------------- }

  // plain text, e.g. <p>Some text</p>
  TPlainTextEntity = class(TBasicEntity)
  strict private
    // content (if any)
    FContent: string;
  public
    constructor Create(AOwner: TObjectList); override;
    property Content: string read FContent write FContent;
  end;

  { -------------------------- VARIABLES AND FIELDS -------------------------- }

  // the variable is replaced with a text, no alt text (see TIfVarEntity below),
  // e.g. {{FONT_NAME}}
  TVarEntity = class(TBasicEntity)
  strict private
    // variable name
    FName: string;
  public
    constructor Create(AOwner: TObjectList); override;
    property Name: string read FName write FName;
  end;

  // the datafield, e.g. {{SQLQuery1.Field1}}, IfEmptyField = '', or
  // {{SQLQuery1.Field1??sometext}}, IfEmptyField = 'sometext'
  TDataFieldEntity = class(TBasicEntity)
  strict private
    // field
    FField: TField;
    // what to do if
    FIfEmptyField: string;
  public
    constructor Create(AOwner: TObjectList); override;
    destructor Destroy; override;

    property Field: TField read FField write FField;
    property IfEmptyField: string read FIfEmptyField write FIfEmptyField;
  end;

  { ----------------------------------- IF ----------------------------------- }

  // common ancestor for all the TIf...Entity
  TBasicIfEntity = class(TBasicEntity)
  strict private
    FIfActions,
    FIfActionsElse: TObjectList;
  public
    constructor Create(AOwner: TObjectList); override;
    destructor Destroy; override;

    property IfActions: TObjectList read FIfActions;
    property IfActionsElse: TObjectList read FIfActionsElse;
  end;

  // {%if VAR%}...{%else%}...{%endif%}--either do somethig if VAR is defined and
  // VAR<>''--or do something else if not
  TIfVarEntity = class(TBasicIfEntity)
  strict private
    FName: string;
  public
    constructor Create(AOwner: TObjectList); override;

    property Name: string read FName write FName;
  end;

  // {%if SQLQuery1%}...{%else%}...{%endif%}--either do somethig if the query is
  // not empty (any record exists) or do something else if it is empty
  TIfDatasetEntity = class(TBasicIfEntity)
  strict private
    FDataset: TDataset;
  public
    constructor Create(AOwner: TObjectList); override;
    destructor Destroy; override;

    property Dataset: TDataset read FDataset write FDataset;
  end;

  // {%if SQLQuery1.Field1%}...{%else%}...{%endif%}--either do somethig if
  // not SQLQuery1.Field1.IsNull (not ...AsString='' !!!) or do something else
  // if it is null
  TIfFieldEntity = class(TBasicIfEntity)
  strict private
    FField: TField;
  public
    constructor Create(AOwner: TObjectList); override;
    destructor Destroy; override;

    property Field: TField read FField write FField;
  end;

  { ---------------------------------- FOR ----------------------------------- }

  TBasicForEntity = class(TBasicEntity)
  strict private
    FActions: TObjectList;
  public
    constructor Create(AOwner: TObjectList); override;
    destructor Destroy; override;

    property Actions: TObjectList read FActions;
  end;

  // {%for TextFile%}...{%endfor%}--do something for each line of the text file
  TForTextFileEntity = class(TBasicForEntity)
  strict private
    FName: string;
  public
    property Name: string read FName write FName;
  end;

  // {%for SQLQuery1%}...{%endfor%}--do something for each record of the query
  // (while not EOF)
  TForDatasetEntity = class(TBasicForEntity)
  strict private
    FDataset: TDataset;
  public
    constructor Create(AOwner: TObjectList); override;
    destructor Destroy; override;

    property Dataset: TDataset read FDataset write FDataset;
  end;

{ TBasicEntity }

constructor TBasicEntity.Create(AOwner: TObjectList);
begin
  AOwner.Add(Self);
  FOwner := AOwner;
end;

destructor TBasicEntity.Destroy;
begin
  FOwner := nil;
  inherited Destroy;
end;

{ TPlainTextEntity}

constructor TPlainTextEntity.Create(AOwner: TObjectList);
begin
  inherited Create(AOwner);
  FContent := '';
end;

{ TVarEntity }

constructor TVarEntity.Create(AOwner: TObjectList);
begin
  inherited Create(AOwner);
  FName := '';
end;

{ TDataFieldEntity }

constructor TDataFieldEntity.Create(AOwner: TObjectList);
begin
  inherited Create(AOwner);
  FIfEmptyField := '';
  FField := nil;
end;

destructor TDataFieldEntity.Destroy;
begin
  FField := nil;
  inherited Destroy;
end;

{ TBasicIfEntity }

constructor TBasicIfEntity.Create(AOwner: TObjectList);
begin
  inherited Create(AOwner);
  FIfActions := TObjectList.Create;
  FIfActionsElse := TObjectList.Create;
end;

destructor TBasicIfEntity.Destroy;
begin
  FreeAndNil(FIfActions);
  FreeAndNil(FIfActionsElse);
  inherited Destroy;
end;

{ TIfVarEntity }

constructor TIfVarEntity.Create(AOwner: TObjectList);
begin
  inherited Create(AOwner);
  FName := '';
end;

{ TIfDatasetEntity }

constructor TIfDatasetEntity.Create(AOwner: TObjectList);
begin
  inherited Create(AOwner);
  FDataset := nil;
end;

destructor TIfDatasetEntity.Destroy;
begin
  FDataset := nil;
  inherited Destroy;
end;

{ TIfFieldEntity }

constructor TIfFieldEntity.Create(AOwner: TObjectList);
begin
  inherited Create(AOwner);
  FField := nil;
end;

destructor TIfFieldEntity.Destroy;
begin
  FField := nil;
  inherited Destroy;
end;

{ TBasicForEntity }

constructor TBasicForEntity.Create(AOwner: TObjectList);
begin
  inherited Create(AOwner);
  FActions := TObjectList.Create;
end;

destructor TBasicForEntity.Destroy;
begin
  FreeAndNil(FActions);
  inherited Destroy;
end;

{ TForDatasetEntity }

constructor TForDatasetEntity.Create(AOwner: TObjectList);
begin
  inherited Create(AOwner);
  FDataset := nil;
end;

destructor TForDatasetEntity.Destroy;
begin
  FDataset := nil;
  inherited Destroy;
end;

