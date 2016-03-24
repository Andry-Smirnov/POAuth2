unit frmmain;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, StdCtrls,
  IniPropStorage, ComCtrls, IdBaseComponent, IdComponent, IdHTTP, uIndyClient,
  uOAuth2HttpClient, uOAuth2Client;

type
  { TMainForm }
  TMainForm = class(TForm)
    btnGet: TButton;
    btnPost: TButton;
    cboResource: TComboBox;
    IniPropStorage: TIniPropStorage;
    Label10: TLabel;
    Label11: TLabel;
    txtFormFields: TMemo;
    StatusBar: TStatusBar;
    txtTook: TEdit;
    txtResponse: TMemo;
    Label9: TLabel;
    txtExpires: TEdit;
    Label7: TLabel;
    Label8: TLabel;
    txtAccessToken: TEdit;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    txtRefreshToken: TEdit;
    txtClientSecret: TEdit;
    txtUser: TEdit;
    Label2: TLabel;
    txtSite: TEdit;
    Label1: TLabel;
    txtPass: TEdit;
    txtClientId: TEdit;
    procedure btnGetClick(Sender: TObject);
    procedure btnPostClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure txtFormFieldsExit(Sender: TObject);
    procedure txtResourceExit(Sender: TObject);
    procedure txtSiteExit(Sender: TObject);
  private
    { private declarations }
    FClient: TIndyHttpClient;
    FOAuthClient: TOAuth2Client;
    FIdHttp: TIdHTTP;
    procedure AddHistory;
  public
    { public declarations }
  end;

var
  MainForm: TMainForm;

implementation

uses
  uOAuth2Tools, uJson, uOAuth2Consts, LCLIntf;

{$R *.lfm}

{ TMainForm }

procedure TMainForm.FormCreate(Sender: TObject);
var
  i, c: integer;
  s: string;
begin
  FIdHttp := TIdHTTP.Create(Self);
  FIdHttp.Request.UserAgent := 'Mozilla/3.0 (compatible; POAuth2)';
  FClient := TIndyHttpClient.Create(FIdHttp);
  FOAuthClient := TOAuth2Client.Create(FClient);
  IniPropStorage.IniFileName := GetAppConfigDir(false) + 'poat.ini';
  StatusBar.SimpleText := 'Settings stored in: ' + IniPropStorage.IniFileName;
  IniPropStorage.Restore;
  IniPropStorage.IniSection := 'general';
  txtSite.Text := IniPropStorage.ReadString('site', txtSite.Text);
  txtUser.Text := IniPropStorage.ReadString('user', txtUser.Text);
  txtPass.Text := IniPropStorage.ReadString('pass', txtPass.Text);
  txtClientId.Text := IniPropStorage.ReadString('client_id', txtClientId.Text);
  txtClientSecret.Text := IniPropStorage.ReadString('client_secret', txtClientSecret.Text);
  cboResource.Text := IniPropStorage.ReadString('resource', cboResource.Text);
  txtFormFields.Lines.Clear;
  IniPropStorage.IniSection := 'postfields';
  c := IniPropStorage.ReadInteger('count', 0);
  for i := 0 to c - 1 do begin
    s := IniPropStorage.ReadString(IntToStr(i), '');
    if s <> '' then
      txtFormFields.Lines.Add(s);
  end;
  IniPropStorage.IniSection := 'history';
  c := IniPropStorage.ReadInteger('count', 0);
  for i := 0 to c - 1 do begin
    s := IniPropStorage.ReadString(IntToStr(i), '');
    if s <> '' then
      cboResource.Items.Add(s);
  end;
{$IFDEF Linux}
  // Find a monospace font
  if Screen.Fonts.IndexOf('DejaVu Sans Mono') <> -1 then begin
    txtResponse.Font.Name := 'DejaVu Sans Mono'
  end;
{$ENDIF}
end;

procedure TMainForm.FormShow(Sender: TObject);
begin
end;

procedure TMainForm.txtFormFieldsExit(Sender: TObject);
var
  i, c: integer;
begin
  c := txtFormFields.Lines.Count;
  for i := c - 1 downto 0 do begin
    if Trim(txtFormFields.Lines[i]) = '' then
      txtFormFields.Lines.Delete(i);
  end;
end;

procedure TMainForm.txtResourceExit(Sender: TObject);
begin
  cboResource.Text := AddLeadingSlash(cboResource.Text);
end;

procedure TMainForm.txtSiteExit(Sender: TObject);
begin
  txtSite.Text := RemoveTrailingSlash(txtSite.Text);
end;

procedure TMainForm.FormClose(Sender: TObject; var CloseAction: TCloseAction);
var
  i, c: integer;
  s: string;
begin
  IniPropStorage.EraseSections;
  IniPropStorage.IniSection := 'general';
  IniPropStorage.WriteString('site', txtSite.Text);
  IniPropStorage.WriteString('user', txtUser.Text);
  IniPropStorage.WriteString('pass', txtPass.Text);
  IniPropStorage.WriteString('client_id', txtClientId.Text);
  IniPropStorage.WriteString('client_secret', txtClientSecret.Text);
  IniPropStorage.WriteString('resource', cboResource.Text);
  IniPropStorage.IniSection := 'postfields';
  c := 0;
  for i := 0 to txtFormFields.Lines.Count - 1 do begin
    s := txtFormFields.Lines[i];
    if s <> '' then begin
      IniPropStorage.WriteString(IntToStr(i), s);
      Inc(c);
    end;
  end;
  IniPropStorage.WriteString('count', IntToStr(c));
  IniPropStorage.IniSection := 'history';
  c := 0;
  for i := 0 to cboResource.Items.Count - 1 do begin
    s := cboResource.Items[i];
    if s <> '' then begin
      IniPropStorage.WriteString(IntToStr(i), s);
      Inc(c);
    end;
  end;
  IniPropStorage.WriteString('count', IntToStr(c));

  IniPropStorage.Save;
  FOAuthClient.Free;
  FClient.Free;
end;

procedure TMainForm.btnGetClick(Sender: TObject);
var
  res: TOAuth2Response;
  start, stop: DWord;
begin
  AddHistory;
  FOAuthClient.Site := txtSite.Text;
  FOAuthClient.GrantType := gtPassword;
  FOAuthClient.UserName := txtUser.Text;
  FOAuthClient.PassWord := txtPass.Text;
  FOAuthClient.ClientId := txtClientId.Text;
  FOAuthClient.ClientSecret := txtClientSecret.Text;
  try
    start := LCLIntf.GetTickCount;
    res := FOAuthClient.Get(cboResource.Text);
    stop := LCLIntf.GetTickCount;
    txtTook.Text := IntToStr(stop - start);
    txtAccessToken.Text := FOAuthClient.AccessToken.AccessToken;
    txtRefreshToken.Text := FOAuthClient.AccessToken.RefreshToken;
    txtExpires.Text := IntToStr(FOAuthClient.AccessToken.ExpiresIn);
    txtResponse.Lines.Clear;
    if res.Code = HTTP_OK then begin
      if IsJson(res.ContentType) then begin
        with TJson.Create do try
          Parse(res.Body);
          Print(txtResponse.Lines);
        finally
          Free;
        end;
      end else begin
        txtResponse.Text := res.Body;
      end;
    end else begin
      txtResponse.Text := Format('Error (%d): %s', [res.Code, res.Body]);
    end;
  except
    on E: Exception do
      txtResponse.Text := Format('%s: %s', [E.ClassName, E.Message]);
  end;
end;

procedure TMainForm.btnPostClick(Sender: TObject);
var
  res: TOAuth2Response;
  start, stop: DWord;
  ff: TStringList;
begin
  AddHistory;
  FOAuthClient.Site := txtSite.Text;
  FOAuthClient.GrantType := gtPassword;
  FOAuthClient.UserName := txtUser.Text;
  FOAuthClient.PassWord := txtPass.Text;
  FOAuthClient.ClientId := txtClientId.Text;
  FOAuthClient.ClientSecret := txtClientSecret.Text;
  ff := TStringList.Create;
  try
    ff.AddStrings(txtFormFields.Lines);
    try
      start := LCLIntf.GetTickCount;
      res := FOAuthClient.Post(cboResource.Text, ff);
      stop := LCLIntf.GetTickCount;
      txtTook.Text := IntToStr(stop - start);
      txtAccessToken.Text := FOAuthClient.AccessToken.AccessToken;
      txtRefreshToken.Text := FOAuthClient.AccessToken.RefreshToken;
      txtExpires.Text := IntToStr(FOAuthClient.AccessToken.ExpiresIn);
      txtResponse.Lines.Clear;
      if res.Code = HTTP_OK then begin
        if IsJson(res.ContentType) then begin
          with TJson.Create do try
            Parse(res.Body);
            Print(txtResponse.Lines);
          finally
            Free;
          end;
        end else begin
          txtResponse.Text := res.Body;
        end;
      end else begin
        txtResponse.Text := Format('Error (%d): %s', [res.Code, res.Body]);
      end;
    except
      on E: Exception do
        txtResponse.Text := Format('%s: %s', [E.ClassName, E.Message]);
    end;
  finally
    ff.Free;
  end;
end;

procedure TMainForm.AddHistory;
var
  s: string;
  i: integer;
begin
  s := cboResource.Text;
  if s <> '' then begin
    i := cboResource.Items.IndexOf(s);
    if i <> -1 then begin
      cboResource.Items.Move(i, 0);
    end else begin
      cboResource.Items.Insert(0, s);
    end;
  end;
end;

end.

