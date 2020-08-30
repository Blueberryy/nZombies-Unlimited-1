--[[
English is the standard language that you should base your ID's off of.
If something isn't found in your language file then it will fall back to English.
Valid languages (from gmod's menu): bg cs da de el en en-PT es-ES et fi fr ga-IE he hr hu it ja ko lt nl no pl pt-BR pt-PT ru sk sv-SE th tr uk vi zh-CN zh-TW
You MUST use one of the above when using translate.AddLanguage
]]

--[[
RULES FOR TRANSLATORS!!
* Only translate formally. Do not translate with slang, improper grammar, spelling, etc.
* Comment out things that you have not yet translated in your language file.
  It will then fall back to this file instead of potentially using out of date wording in yours.
]]

translate.AddLanguage("en", "English")

-- Revive
LANGUAGE.revive                      = "REVIVE"
LANGUAGE.being_revived_by            = "Being revived by %s"  --|
LANGUAGE.reviving                    = "Reviving %s"  --|

-- Wall Buy
LANGUAGE.press_e_to_use              = "Press E to %s"
LANGUAGE.press_e_to_use_x            = "Press E to %s for %s"
LANGUAGE.press_e_to_buy_x            = "Press E to buy %s for %s"
LANGUAGE.press_e_to_pickup_x         = "Press E to pick up %s"
LANGUAGE.requires_electricity        = "Requires Electricity"
LANGUAGE.cant_get_price              = "Can't get Price"
LANGUAGE.unknown_weapon              = "UNKNOWN WEAPON"

-- Barricade
LANGUAGE.repair_barricade            = "Repair Barricade"

-- Debris
LANGUAGE.clear_debris                = "clear debris" --used with LANGUAGE.press_e_to string. Example: "Press E to clear debris"

-- Electricity
LANGUAGE.turn_on_electricity         = "turn on Electricity" --used with LANGUAGE.press_e_to string. Example: "Press E to turn on Electricity"
