-- lua/autorun/client/novoicepanel.lua
-- Désactive complètement le panneau/notification de voix côté client
-- Compatible autorun/client sans dépendre de GM/GAMEMODE.

if SERVER then return end

-- 1) Empêche la création/affichage des panneaux de voix via les hooks standards.
--    Retourner true sur ces hooks bloque le comportement par défaut du gamemode.
hook.Add("PlayerStartVoice", "rt_disable_voice_panel_start", function(ply)
    return true
end)

hook.Add("PlayerEndVoice", "rt_disable_voice_panel_end", function(ply)
    return true
end)

-- 2) Cache le HUD de statut micro (icône voix) si le gamemode l’utilise.
hook.Add("HUDShouldDraw", "rt_hide_voice_hud", function(name)
    -- Certains HUD utilisent "CHudVoiceStatus" (Source/HL2)
    if name == "CHudVoiceStatus" then return false end
    -- Par sécurité, bloque aussi d’autres noms courants (ne casse rien si inexistants)
    if name == "CHudVoiceSelfStatus" then return false end
end)

-- 3) Détruit les panneaux de voix déjà créés par Sandbox/Derma (fallback robuste).
--    Sur Sandbox, la liste est dans g_VoicePanelList avec sous-panneaux "VoiceNotify".
local function removeVoicePanels()
    -- Supprime les notifications déjà créées
    if istable(g_VoicePanelList) and IsValid(g_VoicePanelList) then
        if istable(g_VoicePanelList.Panels) then
            for _, pnl in pairs(g_VoicePanelList.Panels) do
                if IsValid(pnl) then
                    pnl:SetVisible(false)
                    pnl:Remove()
                end
            end
        end
        g_VoicePanelList:SetVisible(false)
        g_VoicePanelList:Remove()
    end
end

-- Appelle une première fois après l’init des entités
hook.Add("InitPostEntity", "rt_kill_voice_panels_init", function()
    timer.Simple(0, removeVoicePanels)
end)

-- Et régulièrement pour contrer toute recréation ultérieure (peu coûteux).
hook.Add("Think", "rt_kill_voice_panels_think", function()
    -- Vérifie s’il y a une liste de panneaux recréée et la supprime
    if istable(g_VoicePanelList) and IsValid(g_VoicePanelList) then
        removeVoicePanels()
    end
end)

-- 4) Bloque explicitement la tentative de création de VoiceNotify si un code tiers essaie.
--    Si le panel-class existe, on intercepte son Create/Init.
timer.Simple(0, function()
    local base = vgui and vgui.GetControlTable and vgui.GetControlTable("VoiceNotify")
    if base and not base._rt_patched then
        base._rt_patched = true

        -- Neutralise Paint pour éviter tout rendu résiduel
        local oldPaint = base.Paint
        base.Paint = function() return end

        -- Neutralise PerformLayout si présent
        if base.PerformLayout then
            local oldLayout = base.PerformLayout
            base.PerformLayout = function() return end
        end

        -- Enregistre la table patchée
        derma.DefineControl("VoiceNotify", "Disabled Voice Panel", base, base.Base or "DPanel")
    end
end)