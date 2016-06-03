class DmgPlumeInteraction extends Interaction;

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
  local LinearColor linCol;
  local float cmax, cmin, delta, h, s, l, c, x, m, r, g, b;

  Viewport = GameViewportClient(Outer);
  PC = Viewport.GetPlayerOwner(0).Actor;

  colorTable.Length = class'Cruzade.CRZFamilyInfo_Mercenary'.default.PrimaryColors.Length;
  for (i=0; i<colorTable.Length; i++)
  {
    class'CRZFamilyInfo_Mercenary'.static.GetCharacterPrimaryColor(i, linCol);
    
    // convert RGB to HSL
    cmax = fmax(fmax(linCol.R, linCol.G), linCol.B);
    cmin = fmin(fmin(linCol.R, linCol.G), linCol.B);
    delta = cmax - cmin;
    x = (linCol.G - linCol.B)/delta;
    h = 60.0 * (delta == 0 ? 0.0 : (cmax == linCol.R) ? (x % 6 + (x-int(x))) : (cmax == linCol.G) ? ((linCol.B - linCol.R)/delta + 2) : ((linCol.R - linCol.G)/delta + 4));
    l = (cmin + cmax)/2;
    s = delta == 0 ? 0.0 : delta / (1.0-abs(2.0*l-1.0));

    // change lightness
    l = 0.85;

    // convert back to RGB
    c = (1 - abs(2*l - 1)) * s;
    x = c * (1 - abs(int(h/60) % 2 - 1));
    m = l - c/2;
    if (h<60) { r=c; g=x; b=0; }
    else if (h<120) { r=x; g=c; b=0; }
    else if (h<180) { r=0; g=c; b=x; }
    else if (h<240) { r=0; g=x; b=c; }
    else if (h<300) { r=x; g=0; b=c; }
    else { r=c; g=0; b=x; }
    
    colorTable[i] = MakeColor((r+m)*255, (g+m)*255, (b+m)*255, 204);
  }
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
    RenderTypingIcon(canvas);
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

function RenderTypingIcon(Canvas canvas)
{
  local int i, playerId;
  local CRZPawn pawn;
  local vector v;
  local vector start, end;
  local float dist, scale;
  local Rotator rot;
  local CRZPlayerReplicationInfo pri;

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

    pri = CRZPlayerReplicationInfo(pawn.PlayerReplicationInfo);

    for (i=0; i<Owner.areTyping.Length; i++)
    {
      if (owner.areTyping[i].PlayerId != playerId)
        continue;
      if (owner.areTyping[i].bTyping)
      {
        end = pawn.Location + vect(0,0,1)*pawn.EyeHeight;
        dist = VSize(end-start);
        scale = (100/FMax(dist,75)+0.15) * canvas.ClipY/1440;

        v = canvas.Project(pawn.Location + vect(0,0,1) * pawn.CylinderComponent.CollisionHeight);        
        canvas.SetPos(v.X - 64 * scale, v.Y - 128 * scale);
        canvas.DrawColor = (PC.WorldInfo.Game != none && PC.WorldInfo.Game.bTeamGame) 
          ? (pawn.PlayerReplicationInfo.Team.TeamIndex == 0 ? Red : Blue) 
          : (pri == none ? White : colorTable[pri.CharacterData.PrimaryColorIndex]);
        canvas.DrawTexture(TypingIconImage, scale);
      }
      break;
    }
  }
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
