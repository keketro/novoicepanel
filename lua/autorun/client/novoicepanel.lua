-- lua/autorun/client/novoicepanel.lua
-- Objectif : ne plus afficher les panneaux/notifications Derma de voix,
--            mais garder le haut-parleur orange (CHudVoiceStatus) lorsque l'on parle.

if SERVER then return end

---------------------------------------------------------------------
-- 1) Bloquer la création des panneaux de voix par les gamemodes/addons
---------------------------------------------------------------------
-- Retourner true sur ces hooks empêche le comportement par défaut de création de panneaux Derma,
-- mais n’empêche PAS l’icône HUD orange (CHudVoiceStatus) d’apparaître.
hook.Add("PlayerStartVoice", "rt_disable_derma_voice_start", function(ply)
    return true
end)

hook.Add("PlayerEndVoice", "rt_disable_derma_voice_end", function(ply)
    return true
end)

---------------------------------------------------------------------
-- 2) Nettoyage/désactivation des panneaux Derma déjà créés (Sandbox)
---------------------------------------------------------------------
local function removeVoicePanels()
    -- Sandbox stocke souvent ses panneaux dans g_VoicePanelList
    if IsValid(g_VoicePanelList) then
        -- Supprime les sous-panneaux
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

-- Premier passage juste après l’init des entités
hook.Add("InitPostEntity", "rt_kill_voice_panels_init", function()
    timer.Simple(0, removeVoicePanels)
end)

-- Surveille une recréation éventuelle et nettoie (léger et sûr)
timer.Create("rt_kill_voice_panels_watch", 1.0, 0, function()
    if IsValid(g_VoicePanelList) then
        removeVoicePanels()
    end
end)

---------------------------------------------------------------------
-- 3) Patch défensif : neutraliser la classe Derma "VoiceNotify" si présente
---------------------------------------------------------------------
timer.Simple(0, function()
    if not vgui or not vgui.GetControlTable then return end
    local base = vgui.GetControlTable("VoiceNotify")
    if base and not base._rt_patched then
        base._rt_patched = true

        -- Neutralise le rendu (aucun dessin)
        base.Paint = function() return end

        -- Neutralise la mise en page si définie
        if base.PerformLayout then
            base.PerformLayout = function() return end
        end

        -- Réenregistre la classe patchée
        derma.DefineControl("VoiceNotify", "Disabled Voice Panel", base, base.Base or "DPanel")
    end
end)
