unit MainForm;

interface


uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, jpeg, ExtCtrls;

const
  WM_PluginShow = WM_USER + 5402;

type
  TForm1 = class(TForm)
    Image1: TImage;
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
  private
    { Private declarations }
    procedure ShowPlugin(var Msg: TMessage); message WM_PluginShow;
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

procedure TForm1.ShowPlugin(var Msg: TMessage);
begin
   Form1.Visible := not Form1.Visible;
end;

procedure TForm1.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
   CanClose := false;
   Visible := false;
end;

end.
