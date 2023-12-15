LazSimpleTemplateParser
=======================

What Is It?
-----------

Sometimes your application needs to display some rich text, and it is easier and faster to use HTML or even a plain text than to program the behavior of visual components (for example, I use IPro components to display HTML). For such situations it would be convenient to use text templates. Not just `Format()` or `StringReplace()` but something slightly more powerful. So one day I created this project.

> [!CAUTION]
> As its name suggests, it is very simple thing and not intended to be a good example of any programming techniques. I created the project for my own purposes and uploaded it in hope that it might be useful to someone else.

The `SimpleTemplateParser` class uses syntax inspired by [Twig](https://twig.symfony.com) and other well-known HTML template systems. The template text seems like this:

``` html
<html>
  <head>
    <title>Dataset</title>
  </head>
  <body style="font-family: {{FONT_NAME}}; font-style: {{FONT_STYLE}}; font-weight: {{FONT_WEIGHT}}; font-size: {{FONT_SIZE}}pt; color: #{{FONT_COLOR}}; background-color: #{{BACK_COLOR}}">
    <h1>Information on {{DATASET1_NAME}}</h1>
    {%if Dataset1%}<dl>
    {%for Dataset%}
      <dt><strong>{{Dataset.Field1}}</strong></dt>
      <dd>{{Dataset.Field2}}</dd>
    {%endfor%}
    </dl>
    {%else%}<em>{{EMPTY_INFO}}</em>{%endif%}
  </body>
</html>
```

You may notice the identifier `Query1`, which hints that the template engine is working with data sets and data fields. This is true.

Template Syntax
-------------

All template text consists of regular text and special inserts. The markers of these special inserts are the symbols `{{`, `}}`, `{%`, and `%}`. Double curly braces `{{ }}` indicate data to be inserted, and curly braces with a percentage `{% %}` mark keywords (these braces nesting not allowed). Additionally, the double question mark symbol `??` is used, see below. Here is a full list of the possible syntax entities:

### Plain Text

* *plain text:* neither `{{` nor `{%` open braces, output is the same text

### Data Output

* *variable or text file line:* `{{VAR_NAME}}` (the name is case-insensitive), output is a value of the `TSimpleTemplateParser.Variables` array, or a value from `AVarList` parameter of the `CreateContent` procedure (see below), or a text file line, see below
* *data field:* `{{DataSet.FieldName}}` or `{{DataSet.FieldName??Coalesce string}}`, output is a value of the field from current dataset record. If the field is null and coalesce string is specified then output is the coalesce string

### Conditional Operators (If)

* *if (with variable):* `{%if VAR_NAME%}...{%else%}...{%endif%}` or `{%if VAR_NAME%}...{%endif%}`. Checks `TSimpleTemplateParser.Variables[VAR_NAME]` and `AVarList` parameter of the `CreateContent` procedure (see below). If it exists then process a part between `{%if…}` and `{%else%}`, otherwise process a part between `{%else%}` and `{%endif%}` (if specified). **The parser doesn't check the variable value, only its existence!**
* *if (with text file alias):* `{%if Text%}...{%else%}...{%endif%}` or `{%if Text%}...{%endif%}`. Checks if the text file alias is presented in the `TSimpleTemplateParser.TextFiles` array. If it exists then process a part between `{%if…}` and `{%else%}`, otherwise process a part between `{%else%}` and `{%endif%}` (if specified)
* *if (with dataset):* `{%if Dataset%}...{%else%}...{%endif%}` or `{%if Dataset%}...{%endif%}`. Checks the dataset. If it is not empty then process a part between `{%if…}` and `{%else%}`, otherwise process a part between `{%else%}` and `{%endif%}` (if specified)
* *if (with data field):* `{%if Dataset.Field%}...{%else%}...{%endif%}` or `{%if Dataset.Field%}...{%endif%}`. Checks the field value. If it is not NULL then process a part between `{%if…}` and `{%else%}`, otherwise process a part between `{%else%}` and `{%endif%}`  (if specified). **The parser doesn't check the field type and value, only NULL / not NULL!**

### Loop Operators (For)

* *for (with text file alias):* `{%for Text%}...{{Text}}...{%endfor%}`. Enumerates all lines in the text file (alias is a value in the `TSimpleTemplateParser.TextFiles` array) and processes each line. Variable with the same name as the text file alias (`Text`) outputs as the text file line, empty lines are skipped
* *for (with dataset):* `{%for Dataset%}...{%endfor%}`. Enumerates all dataset records and processes each record (there might be field values, if-checks, etc.).

Thats all! It is **really** simple parser.

Thus, the demo code above means:

``` html
<html>
  <head>
    <title>Dataset</title>
  </head>
  <body style="font-family: {{FONT_NAME}}; font-style: {{FONT_STYLE}}; font-weight: {{FONT_WEIGHT}}; font-size: {{FONT_SIZE}}pt; color: #{{FONT_COLOR}}; background-color: #{{BACK_COLOR}}"> <!-- substitute font properties, the calling application must specify these values via parser's Variables array-->
    <h1>Information on {{DATASET1_NAME}}</h1> <!-- it is a variable too -->
    {%if Dataset1%}<dl> <!-- if the dataset is not empty... -->
    {%for Dataset%} <!-- for each record write two field values -->
      <dt><strong>{{Dataset.Field1}}</strong></dt>
      <dd>{{Dataset.Field2}}</dd>
    {%endfor%}
    </dl>
    {%else%}<em>{{EMPTY_INFO}}</em>{%endif%} <!-- ...else write EMPTY_INFO variable value instead of the <dl> element -->
  </body>
</html>
```

Files
-----
The `simpletemplateparser.pas` module contains the main `TSimpleTemplateParser` class.

The `parserentities.inc` module contains auxiliary classes that implement particular types of syntactic tokens. The `textfilecontents.inc` file contains another auxiliary class to simplify work with text files.

Folder `demo` belong to the demo project. It is very basic, just shows a list of fake news from text file `news.txt`.

Dependencies
------------
It doesn't require anything special to compile the code other than the standard LCL package. Tested on Lazarus 2.2.6, should work on earlier (more or less modern) and later versions.

Public Properties And Methods
------------

``` delphi
constructor Create(ATemplate: string);
```

Create a new instance of the class. `ATemplate` is a template content (text).

``` delphi
procedure AddDataset(Dataset: TDataset; DisableScrollEvents: Boolean = True);
procedure RemoveDataset(Dataset: TDataset);
```

Add / remove the dataset. The `DisableScrollEvents` option means: if it is true then the engine will temporarily remove the dataset's `BeforeScroll` / `AfterScroll` event handlers when inserting the data.

> [!WARNING]
> Add all datasets you need **before** parsing because `Parse` method uses the dataset list to properly parse some commands like `{%if ...%}`, `{%for ...%}`, etc.

``` delphi
procedure Parse;
```

Start parsing. Usually you do not need to call this method manually because it is called from `CreateContent`.

``` delphi
procedure CreateContent(AVarList: TStrings = nil);
```

Insert the previously stored constants, variables, dataset data, etc. into the `Content` string. `AVarList` is a list of 'local' variables. But the `Variables` array takes precedence if some variable name is present here and there: the variables from `AVarList` are inserted in a place of `{{VAR_NAME}}` if the `Variables` array does not contain the given name.

``` delphi
property Content: string read FContent;
```

The content after inserting the data into the template (i.e. `CreateContent` call).

``` delphi
property Variables[Name: string]: string;
```

A list of variables for `{{VAR_NAME}}` substitution.

``` delphi
property TextFiles[Name: string]: string;
```

A list of text file aliases and paths. E.g.: `TextFiles['Text'] := 'C:\myproject\mytext.txt'`.

Demo
----
The demo project uses IPro components and can be compiled under both Windows and GNU/Linux.

Author
------
Copyright (c) 2023, Michael Demidov

Visit my GitHub page to check for updates, report issues, etc.: https://github.com/MichaelDemidov

Drop me an e-mail at: michael.v.demidov@gmail.com
