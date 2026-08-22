--[[
	PAINEL DE ATALHOS DA WUNNY — aberto e fechado com a tecla H.

	Existe porque as habilidades novas da Wunny são disparadas por teclas e por cliques
	que o jogo não anuncia em lugar nenhum: R/V/B não aparecem na tela de Controles
	(são AddKeyDownHandler do mod, não CONTROL_* do vanilla, e a tela de opções só lista
	os CONTROL_*), e as ações de botão direito só se revelam se você já estiver com o
	mouse em cima da coisa certa. Sem este painel, a única fonte é a descrição da tela
	de seleção de personagem, que some assim que o jogo começa.

	POR QUE UM WIDGET DE HUD E NÃO UMA TELA (TheFrontEnd:PushScreen)
	Uma screen empilhada rouba o foco do input e, em servidor, o jogo continua rodando
	atrás dela — abrir a lista de atalhos no meio de uma luta viraria morte. Como filho
	de "controls", o painel é só pixel: não é focável, não consome clique
	(SetClickable(false) abaixo) e some junto com o resto da HUD quando o jogador
	esconde a interface. Nada aqui toca em estado de jogo, então não há lado servidor.

	TUDO AQUI É CLIENTE. Este arquivo nunca roda no servidor dedicado e não lê nem
	escreve nada do personagem além de `owner.prefab` — de propósito: se ele dependesse
	de netvar (forma sintonizada, o que já está destravado) precisaria de replicação, e
	o orçamento de rede da Wunny já é o problema central do mod (ver
	scripts/wunny_virtualtags.lua). O painel lista o que os atalhos SÃO, não o estado
	atual deles.
]]

local Widget = require "widgets/widget"
local Image = require "widgets/image"
local Text = require "widgets/text"

--------------------------------------------------------------------------------
-- Conteúdo. Ao adicionar um atalho novo ao mod, a linha entra AQUI — é a única
-- parte deste arquivo que se mexe no dia a dia.
--
-- Tipos de linha:
--   { header = "..." }          seção
--   { key = "...", desc = "..." }  atalho (coluna esquerda / coluna direita)
--   { note = "..." }            observação, largura cheia, apagada
--------------------------------------------------------------------------------
local ROWS = {
	{ header = "TECLADO" },
	{ key = "V", desc = "Salto livre: pula na direção em que a Wunny está virada." },
	{ key = "R", desc = "Toca-relâmpago: liga/desliga a corrida subterrânea." },
	{ key = "B", desc = "Entra e sai da forma de coelho sintonizada." },
	{ key = "H", desc = "Abre e fecha este painel." },
	{ note = "A toca-relâmpago corre 60% mais rápido, e a fome sobe na mesma proporção." },

	{ header = "BOTÃO DIREITO" },
	{ key = "numa parede", desc = "Saltar: pula pro outro lado." },
	{ key = "numa casa de coelho", desc = "Sintonizar: destrava a forma e escolhe qual o B ativa." },
	{ key = "no mapa, numa toca", desc = "Cavar até aqui: viaja na hora, custa fome pela distância." },
	{ note = "Só paredes simples (madeira, palha, pedra e ruínas) podem ser saltadas." },
	{ note = "O salto some com as mãos ocupadas ou montada — as animações não existem." },
}

--------------------------------------------------------------------------------
-- Layout. As coordenadas são as da resolução virtual do jogo (RESOLUTION_X 1280 x
-- RESOLUTION_Y 720): com SCALEMODE_PROPORTIONAL + ANCHOR_MIDDLE nos dois eixos, a
-- origem é o centro da tela e x vai de -640 a 640, y de -360 a 360. É por isso que
-- o painel tem as mesmas proporções em qualquer resolução real.
--------------------------------------------------------------------------------
-- ATENÇÃO ao mexer nos textos de ROWS: o Text do DST NÃO quebra linha sozinho (quem faz
-- isso é SetMultilineTruncatedString, que não usamos aqui), então uma descrição maior que
-- RIGHT_W simplesmente vaza por cima da borda do painel em vez de dar erro. As larguras
-- abaixo comportam ~64 caracteres na coluna da direita, com a maior linha atual em 56.
local PANEL_W = 960
local PAD_X = 34
local PAD_Y = 24

local TITLE_H = 52
local HEADER_H = 40
local ROW_H = 30
local NOTE_H = 26

-- Coluna esquerda alinhada à DIREITA e a direita à ESQUERDA: as duas encostam na
-- calha do meio, então "V" e "numa casa de coelho" terminam no mesmo x e as
-- descrições todas começam no mesmo x, sem depender do tamanho de cada rótulo.
local LEFT_W = 280
local GUTTER = 22
local CONTENT_X = -PANEL_W * .5 + PAD_X
local LEFT_X = CONTENT_X + LEFT_W * .5
local RIGHT_X0 = CONTENT_X + LEFT_W + GUTTER
local RIGHT_W = (PANEL_W * .5 - PAD_X) - RIGHT_X0
local RIGHT_X = RIGHT_X0 + RIGHT_W * .5

local GOLD = { 1, .86, .38, 1 }
local WHITE = { 1, 1, 1, 1 }
local DIM = { .74, .72, .66, 1 }

local function RowHeight(row)
	if row.header ~= nil then
		return HEADER_H
	elseif row.note ~= nil then
		return NOTE_H
	end
	return ROW_H
end

--------------------------------------------------------------------------------

local WunnyHelpPanel = Class(Widget, function(self, owner)
	Widget._ctor(self, "WunnyHelpPanel")

	self.owner = owner

	self:SetScaleMode(SCALEMODE_PROPORTIONAL)
	self:SetHAnchor(ANCHOR_MIDDLE)
	self:SetVAnchor(ANCHOR_MIDDLE)
	-- Sem isto o painel entra na varredura de clique da HUD e pode comer um clique de
	-- ataque enquanto está aberto. Ele é decoração; o único input que lhe pertence é o
	-- H, tratado no modmain.
	self:SetClickable(false)

	local panel_h = PAD_Y * 2 + TITLE_H
	for _, row in ipairs(ROWS) do
		panel_h = panel_h + RowHeight(row)
	end

	-- A borda é só um quadrado maior ATRÁS do fundo: adicionada primeiro porque em
	-- Widget a ordem de AddChild é a ordem de desenho, e o preto por cima recorta o
	-- miolo dela, deixando visível apenas a moldura de 3px.
	local border = self:AddChild(Image("images/global.xml", "square.tex"))
	border:SetSize(PANEL_W + 6, panel_h + 6)
	border:SetTint(GOLD[1], GOLD[2], GOLD[3], .45)

	local bg = self:AddChild(Image("images/global.xml", "square.tex"))
	bg:SetSize(PANEL_W, panel_h)
	bg:SetTint(0, 0, 0, .85)

	local y = panel_h * .5 - PAD_Y

	local title = self:AddChild(Text(HEADERFONT, 38, "ATALHOS DA WUNNY"))
	title:SetColour(unpack(GOLD))
	title:SetPosition(0, y - TITLE_H * .5)
	y = y - TITLE_H

	for _, row in ipairs(ROWS) do
		local h = RowHeight(row)

		if row.header ~= nil then
			local w = self:AddChild(Text(HEADERFONT, 26, row.header))
			w:SetColour(unpack(GOLD))
			-- Região da largura inteira do conteúdo centrada em x=0, então HAlign
			-- LEFT faz o texto começar exatamente na margem esquerda do painel.
			w:SetRegionSize(PANEL_W - PAD_X * 2, h)
			w:SetHAlign(ANCHOR_LEFT)
			w:SetPosition(0, y - h * .5)
		elseif row.note ~= nil then
			local w = self:AddChild(Text(CHATFONT, 20, row.note))
			w:SetColour(unpack(DIM))
			w:SetRegionSize(PANEL_W - PAD_X * 2, h)
			w:SetHAlign(ANCHOR_LEFT)
			w:SetPosition(0, y - h * .5)
		else
			local k = self:AddChild(Text(HEADERFONT, 24, row.key))
			k:SetColour(unpack(GOLD))
			k:SetRegionSize(LEFT_W, h)
			k:SetHAlign(ANCHOR_RIGHT)
			k:SetPosition(LEFT_X, y - h * .5)

			local d = self:AddChild(Text(CHATFONT, 22, row.desc))
			d:SetColour(unpack(WHITE))
			d:SetRegionSize(RIGHT_W, h)
			d:SetHAlign(ANCHOR_LEFT)
			d:SetPosition(RIGHT_X, y - h * .5)
		end

		y = y - h
	end

	-- Nasce fechado: quem abre é o H.
	self:Hide()
end)

function WunnyHelpPanel:Toggle()
	if self.shown then
		self:Hide()
	else
		self:Show()
	end
end

return WunnyHelpPanel
