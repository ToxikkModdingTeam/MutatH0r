TOXIKK Mutator Pack
===

Installation through [Steam Workshop](http://steamcommunity.com/sharedfiles/filedetails/?id=603855831):   
SteamApps\\workshop\\content\\324810\\603855831

Manual installation (without Steam Workshop):   
SteamApps\\common\\TOXIKK\\UDKGame\\Script\\[MutatH0r.u](http://toxikk.beham.biz/toxikkredirect2/MutatH0r.u)
SteamApps\\common\\TOXIKK\\UDKGame\\Config\\[UDKMutatH0r.ini](http://toxikk.beham.biz/toxikkredirect2/UDKMutatH0r.ini)


The INI file settings are optimized for a server that runs a combination of Vampire + Regen/Decay + Stim Head.

**Included Mutators:**

<a href="#DmgPlume">Damage Plumes</a>
| <a href="#ComboGib">ComboGib</a>
| <a href="#Roq3t">Roq3t</a>
| <a href="#SuperStingray">SuperStingray</a>
| <a href="#Vampire">Vampire</a>
| <a href="#RegenDecay">Regen/Decay</a>
| <a href="#StimHead">StimHead</a>
| <a href="#PulseHead">PulseHead</a>
| <a href="#Loadout">Loadout</a>
<p>


<a name="DmgPlume"/>
Damage Plumes
---
Pops out a number over your target's head whenever you hit it: [YouTube](https://www.youtube.com/watch?v=QYlPOBKEHio)   
The plumes can be configured through UDKMutatH0r.ini, which can hold sections for multiple plume presets like
\[Small DmgPlumeConfig\], ...   
In your console you can select a preset with the command: plumes \<preset-name\>.   
Default presets are: off, small, large.
You can modify them or add new ones as you see fit.

<a name="ComboGib"/>
ComboGib
---
Stingray bounces players with primary or secondary fire and tags them to be killed with the other.  
After 2 seconds or when a player touches the ground he becomes untagged again.  
Players get a green tag when they are hit with the beam. They can then be killed with a plasma ball.  
Players get a yellow tag then when they are hit with 2 balls. They can then be killed with a beam.  
In SquadAssault you can untag your team mates with the shot that would normally kill them.


<a name="Roq3t"/>
Roq3t
---
Direct rocket hits deal 120 damage, but any splash is reduced to 0.5x regular.  
Knockback is increased to 1.5x and self-damage is disabled.  
All of that can be configured individually in the INI.  


<a name="SuperStingray"/>
SuperStingray
---
Stingray plasma ball is reduced to 17 dmg/hit (from 35) but it has splash damage and knockback.  
This allows you to climb up walls!


<a name="Vampire"/>
Vampire
---
When you deal damage, 75% of it is given to you as health.


<a name="RegenDecay"/>
Regen/Decay
---
Allows to increase/decrease health and armor over time.  
Typical use cases are health/armor decay (if they are above 100/50) or automatic health regeneration.


<a name="StimHead"/>
Stim Head
---
Extra health and armor makes you an easier target for head shots.  
Scales a player's head size by (health + armor)/100.


<a name="PulseHead"/>
Pulse Head
---
Pulses a player's head size over time so you can get easier head shots, if you can time it right.


<a name="Loadout"/>
Loadout
---
Lets you spawn with certain weapons in your inventory.  
Also has options to set infinite ammo and/or disable regular weapon spawns.

