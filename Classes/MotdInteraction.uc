class MotdInteraction extends Interaction;

// defined at initialization
var GameViewportClient Viewport;
var PlayerController PC;
var CRZMutator_Motd Owner;

// static
var Font HeaderFont, MessageFont;
var Color TextColor;
var Color BackgroundColor;
var EHudMode PrevHudMode;

// instance
var bool Visible;

static function MotdInteraction Create(CRZMutator_Motd theOwner, PlayerController controller, optional bool bReturnExisting=true)
{
  local MotdInteraction newInt;
  local int i;
 
  if (bReturnExisting)
  {
    for (i=0; i<controller.Interactions.length; i++)
    {
      if (controller.Interactions[i].class == default.class)
        return MotdInteraction(controller.Interactions[i]);
    }
  }
 
  newInt = new(LocalPlayer(controller.Player).ViewportClient) default.class;
  LocalPlayer(controller.Player).ViewportClient.InsertInteraction(newInt, 0);
  //controller.Interactions.InsertItem(0, newInt);
  controller.Interactions.AddItem(newInt);
  newInt.Owner = theOwner;
  return newInt;
}
 
function Initialized()
{
  Viewport = GameViewportClient(Outer);
  PC = Viewport.GetPlayerOwner(0).Actor;
}

exec function Motd()
{
  Visible = !Visible;
}

function bool OnReceivedNativeInputKey(int controllerId, name key, EInputEvent eventType, optional float amountDepressed, optional bool bGamepad)
{
  if (Key == 'SpaceBar' && Visible)
  {
    Visible = false;
    return true;
  }
  return super.OnReceivedNativeInputKey(controllerId, key, eventType, amountDepressed, bGamepad);
}

event PostRender(Canvas canvas)
{
  local CRZHudWrapper wrapper;

  if (Owner == None) // actor destroyed when match is over
    return;

  // show MOTD during PreMatchLobby (after intro, before game)
  wrapper = CRZHudWrapper(PC.myHUD);
  if (wrapper != None)
  {
    if (wrapper.CurrentHudMode != PrevHudMode)
    {
      if (wrapper.CurrentHudMode == HM_PreMatchLobby)
        Visible = true;
      else if (PrevHudMode == HM_PreMatchLobby)
        Visible = false;
      PrevHudMode = wrapper.CurrentHudMode;
    }
  }


  if (Visible)
    RenderMotd(canvas);
}

function RenderMotd(Canvas canvas)
{
  local float x,y,w,h,width, height, messageY;
  local int i;
  local float padding;
  local string line;

  padding = 8;

  canvas.Font = HeaderFont;
  for (i=0; i<owner.WelcomeHeader.Length; i++)
  {
    line = owner.WelcomeHeader[i];
    if (line == "") line = "Äj";
    canvas.TextSize(line, w, h, 1.0, 1.0);
    width = FMax(width, w);
    height += h;
  }
  messageY = height;
  canvas.Font = MessageFont;
  for (i=0; i<owner.WelcomeMessage.Length; i++)
  {
    line = owner.WelcomeMessage[i];
    if (line == "") line = "Äj";
    canvas.TextSize(line, w, h, 1.0, 1.0);
    width = FMax(width, w);
    height += h;
  }

  x = (canvas.ClipX - width) / 2;
  y = 150;
  canvas.DrawColor = BackgroundColor;
  canvas.SetPos(x - padding, y - padding);
  canvas.DrawRect(width + 2*padding, height + 2*padding);
  
  canvas.DrawColor = TextColor; 
  canvas.Font = HeaderFont;
  canvas.SetPos(x, y);
  canvas.DrawText(owner.WelcomeHeaderString, false, 1.0, 1.0);
  canvas.Font = MessageFont;
  canvas.SetPos(x, y + messageY);
  canvas.DrawText(owner.WelcomeMessageString, false, 1.0, 1.0);
}

event NotifyGameSessionEnded()
{
  Owner = None;
  PC = None;
  Viewport = None;

  super.NotifyGameSessionEnded();
}

DefaultProperties
{
  HeaderFont=Font'UI_Fonts.Fonts.UI_Fonts_Positec36'
  MessageFont=Font'UI_Fonts.Fonts.UI_Fonts_Positec18'
  TextColor=(R=255,G=255,B=255,A=255)
  BackgroundColor=(R=0, G=0, B=0, A=128)
  PrevHudMode = HM_None
}
