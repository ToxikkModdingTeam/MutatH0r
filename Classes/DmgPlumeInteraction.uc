class DmgPlumeInteraction extends Interaction;

const DrawChatIconOnAllPlayersForTesting = false;

// defined at initialization
var GameViewportClient Viewport;
var PlayerController PC;
var DmgPlumeActor Owner;

// static
var Font PlumeFont;
var Font TextFont;
var Color White, Red, Blue;
//var Color CrosshairNameColor;
var Texture2D TypingIconImage;

var array<Color> colorTable;

static function DmgPlumeInteraction Create(DmgPlumeActor theOwner, PlayerController controller, optional bool bReturnExisting=true)
{
  local DmgPlumeInteraction newInt;
  local int i;
 
  if (bReturnExisting)
  {
    for (i=0; i<controller.Interactions.length; i++)
    {
      if (controller.Interactions[i].class == default.class)
        return DmgPlumeInteraction(controller.Interactions[i]);
    }
  }
 
  newInt = new(LocalPlayer(controller.Player).ViewportClient) default.class;
  LocalPlayer(controller.Player).ViewportClient.InsertInteraction(newInt, 0);
  controller.Interactions.InsertItem(0, newInt);
  newInt.Owner = theOwner;
  return newInt;
}
 
function Initialized()
{
  local int i;
  local LinearColor rgb;
  local float h, s, l;

  Viewport = GameViewportClient(Outer);
  PC = Viewport.GetPlayerOwner(0).Actor;

  colorTable.Length = class'Cruzade.CRZFamilyInfo_Mercenary'.default.PrimaryColors.Length;
  for (i=0; i<colorTable.Length; i++)
  {
    class'CRZFamilyInfo_Mercenary'.static.GetCharacterPrimaryColor(i, rgb);
    RgbToHsl(rgb, h, s, l);
    l = 0.85; // change lightness
    HslToRgb(h, s, l, rgb);   
    colorTable[i] = MakeColor(rgb.R*255, rgb.G*255, rgb.B*255, 204);
  }
}

simulated function RgbToHsl(LinearColor rgb, out float h, out float s, out float l)
{
  local float cmax, cmin, d;

  cmax = fmax(fmax(rgb.R, rgb.G), rgb.B);
  cmin = fmin(fmin(rgb.R, rgb.G), rgb.B);
  l = (cmin + cmax)/2.0;
  if (cmax == cmin)
  {
    h = 0;
    s = 0;
  }
  else
  {
    d = cmax - cmin;
    s = l > 0.5 ? d / (2.0-cmax-cmin) : d/(cmax+cmin);
    if (cmax == rgb.R) 
      h = (rgb.G - rgb.B)/d + (rgb.G < rgb.B ? 6.0 : 0.0);
    else if (cmax == rgb.G)
      h = (rgb.B - rgb.R)/d + 2.0;
    else
      h = (rgb.R - rgb.G)/d + 4.0;
    h /= 6.0;
  }
}

simulated function HslToRgb(float h, float s, float l, out LinearColor rgb)
{
  local float q, p;

  if (s == 0)
  {
    rgb.R = l;
    rgb.G = l;
    rgb.B = l;
  }
  else
  {
    q = l < 0.5 ? l * (1.0+s) : (l+s-l*s);
    p = 2.0 * l - q;
    rgb.R = HueToRgb(p, q, h + 1.0/3.0);
    rgb.G = HueToRgb(p, q, h);
    rgb.B = HueToRgb(p, q, h - 1.0/3.0);
  }
}

simulated function float HueToRgb(float p, float q, float t)
{
  if (t < 0) t += 1.0;
  if (t > 1) t -= 1.0;
  if (t < 1.0/6.0) return p + (q - p) * 6.0 * t;
  if (t < 1.0/2.0) return q;
  if (t < 2.0/3.0) return p + (q - p) * (2.0/3.0 - t) * 6.0;
  return p;
}

exec function KillSound(optional string soundName)
{
  local int i;
  local string msg;
  local array<DmgPlumeActor.ResourceInfo> sounds;

  if (soundName == "")
  {
    sounds = Owner.KillSounds;
    for (i=0; i<sounds.Length; i++)
    {
      if (msg != "") msg = msg $ ", ";
      msg = msg $ "<font color=\"" $ ((sounds[i].Label ~= Owner.KillSound) ? "#ffff00" : "#00ffff") $ "\">" $ sounds[i].Label $ "</font>";
    }

    PC.ClientMessage("Usage: <font color=\"#ffff00\">KillSound </font>&lt;<font color=\"#00ffff\">soundName</font>&gt; with one of these sound names: " $ msg);
  }
  else
  {
    if (!Owner.SetKillSound(soundName))
      PC.ClientMessage("Unknown sound name. Use KillSound without a parameter to get a list of supported sounds");
  }    
}


exec function ChatIcon(bool show)
{
  if (Owner != None)
  {
    Owner.bDisableChatIcon = !show;
    Owner.SaveConfig();
  }
}

event PostRender(Canvas canvas)
{
  if (Owner == None) // actor destroyed when match is over
    return;

  if (!Owner.bDisableChatIcon)
    RenderTypingIcons(canvas);
}

function RenderTypingIcons(Canvas canvas)
{
  local int i, playerId;
  local CRZPawn pawn;
  local vector start;
  local Rotator rot;

  if (TypingIconImage == None)
    return;

  canvas.Font = TextFont;
  PC.GetPlayerViewPoint(start, rot);

  foreach PC.WorldInfo.AllPawns(class'CRZPawn', pawn)
  {
    if (pawn.CurrentStealthFactor >= 0.5)
      continue;
    if (pawn.PlayerReplicationInfo == None)
      continue;
 
    playerId = pawn.PlayerReplicationInfo.PlayerID;
    if (playerId == PC.PlayerReplicationInfo.PlayerID)
      continue;

    if (!PC.CanSee(pawn))
      continue;

    if (DrawChatIconOnAllPlayersForTesting)
      DrawChatIconForPlayer(pawn, start, canvas);
    else
    {
      for (i=0; i<Owner.typingPlayers.Length; i++)
      {
        if (owner.typingPlayers[i].PlayerId != playerId)
          continue;
        if (owner.typingPlayers[i].bTyping)
          DrawChatIconForPlayer(pawn, start, canvas);
        break;
      }
    }
  }
}

simulated function DrawChatIconForPlayer(Pawn pawn, vector start, Canvas canvas)
{
  local vector end, v;
  local float dist, scale;
  local CRZPlayerReplicationInfo pri;

  end = pawn.Location + vect(0,0,1)*pawn.EyeHeight;
  dist = VSize(end-start);
  scale = (100/FMax(dist,75)+0.15) * canvas.ClipY/1440;

  pri = CRZPlayerReplicationInfo(pawn.PlayerReplicationInfo);

  v = canvas.Project(pawn.Location + vect(0,0,1) * pawn.CylinderComponent.CollisionHeight);        
  canvas.SetPos(v.X - 64 * scale, v.Y - 128 * scale);
  canvas.DrawColor = (PC.WorldInfo.Game != none && PC.WorldInfo.Game.bTeamGame) 
    ? (pawn.PlayerReplicationInfo.Team.TeamIndex == 0 ? Red : Blue) 
    : (pri == none ? White : colorTable[pri.CharacterData.PrimaryColorIndex]);
  canvas.DrawTexture(TypingIconImage, scale);
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
  PlumeFont=Font'KismetGame_Assets.Fonts.JazzFont_05'
  TextFont=Font'UI_Fonts.Fonts.UI_Fonts_Positec18'
  TypingIconImage = Texture2D'MutatH0r_Content.ChatBubble'
  White = (R=255, G=255, B=255, A=204)
  Red = (R=255, G=220, B=220, A=204)
  Blue = (R=220, G=220, B=255, A=204)
}
