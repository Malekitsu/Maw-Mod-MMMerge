
# New events
## BuildMonsterInformationBox
* Basic table arguments: `Name`, `Attack`, `Damage`, `ArmorClass`, `HitPoints`, `SpellFirst`, `SpellSecond`, `EffectsHeader`, `ResistancesHeader`
* Identified arguments: `IdentifiedName`, `IdentifiedAttack`, `IdentifiedDamage`, `IdentifiedArmorClass`, `IdentifiedHitPoints`, `IdentifiedSpellFirst`, `IdentifiedSpellSecond`, `IdentifiedEffects`, `IdentifiedResistances`
* Advanced table arguments: `Effects`, `Resistances`
* Misc arguments: `Tooltip`, `COLOR_LABEL`

You can set each table for certain element to `nil` or `false`, this will cause it to be not drawn.

A basic table for single tooltip element looks like this:
```lua
{
    Text = "test", -- what will be written into tooltip, can contain special codes inserted with StrRight(), StrLeft(), StrColor() functions
    Font = Game.Comic_fnt, -- font that will be used for writing text. If you change it, pass fields like Game.Smallnum_fnt, not Game.FontSmallnum
    Color = 0x57AA, -- default color used for written text, can be overridden with StrColor()
    ShadowColor = 0, -- meaning same as in Grayface's reference for structs.Fnt:Draw()
    Bottom = 0, -- see above
    Opaque = 0, -- see above
    X = 157, -- coordinates that text will be written at
    Y = 123, -- see above
}
```

`Name` is special case - since it is always drawn centered, setting X or Y won't have any effect. Also some formatting parameters (`ShadowColor`, `Bottom`, `Opaque`) will not work (see Grayface's dcoumentation for `structs.Fnt:DrawCentered()`), and one extra (`ReduceLineHeight`) is present.

`EffectsHeader` and `ResistancesHeader` are another special case, they have extra parameters:
```lua
{
    UseIndividualTextCoordinates = false, -- if set to true, coordinates for each text element of accompanying advanced table (for effects and resistances) will be taken directly from it, otherwise they are based on first element position and incremented by XAdd and YAdd for each next item.
    XAdd = 0, -- see above
    YAdd = 10, -- see above
}
```

Identified arguments allow you to check whether the real value of field would be drawn, or that "?" placeholder. Setting them to different values won't do anything ATM.

Advanced table argument (`Effects` and `Resistances`) is an array of basic tables with one extra parameter and looks like this:
```lua
{
    {Text = "test", Font = Game.Comic_fnt, Color = 0x57AA, ShadowColor = 0, Bottom = 0, Opaque = 0, X = 157, Y = 123, Id = 5},
    -- "Id" parameter is id of current item (for effects it is const.MonsterBuff id, and for resistances its index in tooltip)
    -- more elements...
}
```

X and Y coordinates will only have effect if `UseIndividualTextCoordinates` field is false in accompanying header entry.

`Tooltip` field is structs.Dlg entry for monster dialog. In particular, it must be passed to structs.Fnt.Draw() family of functions if you use them. Theoretically you can change some stuff here, haven't tested much, but for sure changing dialog size won't work here. Instead, you can use:
```lua
-- function ChangeMonsterTooltipSize(width, height)
ChangeMonsterTooltipSize(0x200, 0x200)
ChangeMonsterTooltipSize(0x200, nil) -- passing nil for any argument restores default size (0x140)
```

`COLOR_LABEL` field contains color of default label text (that yellow color). You can pass it to StrColor() like this:
```lua
local x = StrColor(t.COLOR_LABEL, "Damage")
```
If you want to change just a single entry color, do something like:
```lua
t.Resistances[2].Color = RGB(111, 111, 111) -- RGB() packs rgb values into single game-readable value
```

There is also new freestanding (global) function called `StrFormatGame()`. You can use it to format original game format strings with different values. Those strings are not provided yet, so best is probably using other `Str*` functions.
```lua
StrFormatGame("%s\f%05u\t080%s\n", StrColor(t.COLOR_LABEL, "Damage"), 0, "500-1000 (phys)")
StrFormatGame("%s\f%05u\t060%s\n", StrColor(t.COLOR_LABEL, "Spell"), 0, "Fireball (100-200)")
```