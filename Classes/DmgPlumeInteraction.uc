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

exec function Plumes(optional string preset)
{
  local array<string> names;
  local string msg, iniPreset;
  local int i;

  preset = Locs(preset);
  if (preset == "")
  {
    if (!GetPerObjectConfigSections(class'DmgPlumeConfig', names)) // names are returned in reverse order
    {
      // if player has no local .ini file, add hardcoded default presets
      names.AddItem("huge");
      names.AddItem("large");
      names.AddItem("small");
    }
    names.AddItem("off");

    for (i=names.Length-1; i>=0; i--)
    {
      if (msg != "") msg = msg $ ", ";
      iniPreset = repl(locs(names[i]), " dmgplumeconfig", "");
      msg = msg $ "<font color=\"" $ (((Owner.bDisablePlumes && iniPreset == "off") || (iniPreset == Owner.DmgPlumeConfig)) ? "#ffff00" : "#00ffff") $ "\">" $ iniPreset $ "</font>";
    }

    PC.ClientMessage("Usage: <font color=\"#ffff00\">plumes </font>&lt;<font color=\"#00ffff\">preset</font>&gt; with one of these presets: " $ msg);
  }
  else
  {
    if (preset == "off")
    {
      Owner.bDisablePlumes = true;
      Owner.SaveConfig();
    }
    else if (Owner.LoadPreset(preset))
    {
      Owner.bDisablePlumes = false;
      Owner.SaveConfig();
    }
    else
      PC.ClientMessage("Plumes: unknown preset: " $ preset);
  }    
}

exec function KillSound(optional string soundName)
{
  local int i;
  local string msg;
  local array<DmgPlumeActor.KillSoundInfo> sounds;

  if (soundName == "")
  {
    sounds = Owner.KillSounds;
    for (i=sounds.Length-1; i>=0; i--)
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



//exec function CrosshairNames(bool show)
//{
//  if (Owner != None)
//  {
//    Owner.bDisableCrosshairNames = !show;
//    Owner.SaveConfig();
//  }
//}

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

  if (!Owner.bDisablePlumes)
    RenderDamagePlumes(canvas);
  //if (!Owner.bDisableCrosshairNames)
  //  RenderCrosshairName(canvas);
  if (!Owner.bDisableChatIcon)
    RenderTypingIcons(canvas);
}

function RenderDamagePlumes(Canvas canvas)
{
  local int i;
  local vector pos;
  local Vector2D textSize;
  local PlumeSpriteInfo plume;
  local int alpha;
  local float sizeScale;
  local float distance;
  local float gravity;

  gravity = Owner.Settings.SpeedY.Fixed + Owner.Settings.SpeedY.Random / 2;

  for (i=0; i<Owner.Plumes.Length; i++)
  {
    plume = Owner.Plumes[i];
    pos = canvas.Project(plume.Location);
    pos.X += plume.SpeedX * plume.Age;
    pos.Y += -plume.SpeedY * plume.Age + gravity * plume.Age * plume.Age;

    if (pos.X < 0 || pos.X >= canvas.ClipX || pos.Y < 0 || pos.Y >= canvas.ClipY)
      continue;

    distance = PC.Pawn == None ? 1000.0 : VSize(PC.Pawn.Location - plume.Location);
    if (distance < 0)
      sizeScale = Owner.Settings.ScaleLarge;
    else if (distance > Owner.Settings.ScaleDistance)
      sizeScale = Owner.Settings.ScaleSmall;
    else
      sizeScale = (1-(distance/Owner.Settings.ScaleDistance)) * (Owner.Settings.ScaleLarge - Owner.Settings.ScaleSmall) + Owner.Settings.ScaleSmall;
   
    canvas.Font = PlumeFont;
    canvas.TextSize(string(plume.Value), textSize.X, textSize.Y, sizeScale, sizeScale);
    if (pos.X + textSize.X / 2 + 1 >= canvas.ClipX)
      continue;

    alpha = int(255.0 * fclamp(1.0 - (plume.Age-0.5)/Owner.Settings.TimeToLive, 0, 1));

    canvas.DrawColor = GetColor(plume);
    canvas.DrawColor.A = alpha;
    canvas.SetPos(pos.X - textSize.X/2, pos.Y - textSize.Y/2);
    canvas.DrawText(string(plume.Value), false, sizeScale, sizeScale);
  }
}

//function RenderCrosshairName(Canvas canvas)
//{
//  local CRZPawn target;
//  local Vector start, end, hitLocation, hitNormal;
//  local Rotator rot;
//  local float width, height;

//  if (PC.Pawn == None)
//    return;
  
//  PC.GetPlayerViewPoint(start, rot);
//  end = start + vector(rot) * 10000;
//  target = CRZPawn(PC.Pawn.Trace(hitLocation, hitNormal, end, start));
//  if (target != None && target.PlayerReplicationInfo != None && target.CurrentStealthFactor <= 0.5)
//  {
//    canvas.Font = TextFont;
//    canvas.TextSize(target.PlayerReplicationInfo.PlayerName, width, height, 1.0, 1.0);
//    canvas.SetPos(canvas.ClipX / 2 - width / 2, canvas.ClipY * 4 / 10 - height / 2);
//    canvas.DrawColor = CrosshairNameColor;
//    canvas.DrawText(target.PlayerReplicationInfo.PlayerName, false, 1.0, 1.0);
//  }
//}

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
      for (i=0; i<Owner.areTyping.Length; i++)
      {
        if (owner.areTyping[i].PlayerId != playerId)
          continue;
        if (owner.areTyping[i].bTyping)
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

simulated function Color GetColor(PlumeSpriteInfo plume)
{
  local PlumeColor prevCol, col;
  local int i,c;

  c = Owner.Settings.PlumeColors.Length;
  prevCol = Owner.Settings.PlumeColors[0];
  for (i=1; i<c; i++)
  {
    col = Owner.Settings.PlumeColors[i];
    if (plume.Value < col.Damage)
      return prevCol.Color;
    prevCol = col;
  }
  return col.Color;
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
//  CrosshairNameColor=(R=255,G=255,B=255,A=255)
  TypingIconImage = Texture2D'MutatH0r_Content.ChatBubble'
  White = (R=255, G=255, B=255, A=204)
  Red = (R=255, G=220, B=220, A=204)
  Blue = (R=220, G=220, B=255, A=204)
}
