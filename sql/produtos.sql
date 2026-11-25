-- ==========================================================
-- produtos.sql - Essence Beauty (Supabase)
-- Como usar: Supabase > SQL Editor > New query > cole tudo > Run
-- Pode rodar mais de uma vez: só cria o que falta e não duplica produtos.
-- ==========================================================

-- ----------------------------------------------------------
-- 1) TABELA DE PRODUTOS
-- pagina    = em qual página o produto aparece:
--             skin-care | maquiagem | cabelos | corpo | kits | promocoes
--             destaques (início, "Produtos") | mais-vendidos (início)
-- categoria = usado nos botões de filtro de cada página
-- preco_original = preço "de" (riscado). Deixe vazio se não tiver desconto.
-- ----------------------------------------------------------
create table if not exists public.produtos (
    id             text primary key default ('p' || substr(md5(random()::text), 1, 8)),
    nome           text not null,
    descricao      text,
    itens_kit      text,
    pagina         text not null check (pagina in ('skin-care','maquiagem','cabelos','corpo','kits','promocoes','destaques','mais-vendidos')),
    categoria      text,
    preco          numeric(10,2) not null check (preco >= 0),
    preco_original numeric(10,2) check (preco_original is null or preco_original >= 0),
    imagem         text,
    ordem          int not null default 100,
    ativo          boolean not null default true,
    criado_em      timestamptz not null default now()
);

create index if not exists produtos_pagina_idx on public.produtos (pagina, ordem);

-- ----------------------------------------------------------
-- 2) ADMINISTRADORES (quem pode cadastrar / editar produtos)
-- Depois de rodar este arquivo, coloque o e-mail de quem vai
-- administrar a loja (precisa ter conta no site, criada em cadastrar.html):
--   insert into public.admins (email) values ('seuemail@exemplo.com');
-- ----------------------------------------------------------
create table if not exists public.admins (
    email text primary key
);

alter table public.admins enable row level security;

create or replace function public.eh_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
    select exists (
        select 1 from public.admins
        where lower(email) = lower(coalesce(auth.jwt() ->> 'email', ''))
    );
$$;

drop policy if exists "admin ve a propria linha" on public.admins;
create policy "admin ve a propria linha" on public.admins
    for select to authenticated
    using (lower(email) = lower(coalesce(auth.jwt() ->> 'email', '')));

-- ----------------------------------------------------------
-- 3) SEGURANÇA (RLS)
-- Qualquer visitante VÊ os produtos ativos; só admin cadastra/edita/exclui.
-- ----------------------------------------------------------
alter table public.produtos enable row level security;

drop policy if exists "todos veem produtos ativos" on public.produtos;
create policy "todos veem produtos ativos" on public.produtos
    for select to anon, authenticated
    using (ativo or public.eh_admin());

drop policy if exists "admin cadastra produtos" on public.produtos;
create policy "admin cadastra produtos" on public.produtos
    for insert to authenticated
    with check (public.eh_admin());

drop policy if exists "admin edita produtos" on public.produtos;
create policy "admin edita produtos" on public.produtos
    for update to authenticated
    using (public.eh_admin())
    with check (public.eh_admin());

drop policy if exists "admin exclui produtos" on public.produtos;
create policy "admin exclui produtos" on public.produtos
    for delete to authenticated
    using (public.eh_admin());

-- ----------------------------------------------------------
-- 4) FOTOS DOS PRODUTOS (Storage, bucket "produtos")
-- As fotos enviadas pela página admin-produtos.html ficam aqui.
-- ----------------------------------------------------------
insert into storage.buckets (id, name, public)
values ('produtos', 'produtos', true)
on conflict (id) do nothing;

drop policy if exists "todos veem fotos de produtos" on storage.objects;
create policy "todos veem fotos de produtos" on storage.objects
    for select to anon, authenticated
    using (bucket_id = 'produtos');

drop policy if exists "admin envia fotos de produtos" on storage.objects;
create policy "admin envia fotos de produtos" on storage.objects
    for insert to authenticated
    with check (bucket_id = 'produtos' and public.eh_admin());

drop policy if exists "admin apaga fotos de produtos" on storage.objects;
create policy "admin apaga fotos de produtos" on storage.objects
    for delete to authenticated
    using (bucket_id = 'produtos' and public.eh_admin());

-- ----------------------------------------------------------
-- 5) PRODUTOS QUE JÁ EXISTIAM NO SITE
-- (os ids são os mesmos de antes, então carrinhos salvos continuam valendo)
-- ----------------------------------------------------------
insert into public.produtos (id, pagina, categoria, nome, descricao, itens_kit, preco, preco_original, imagem, ordem) values
-- SKIN CARE
('sk1', 'skin-care', 'limpeza',    'Água Micelar Suave', 'Remove maquiagem e impurezas sem precisar enxaguar. Fórmula suave que limpa sem ressecar, ideal para peles sensíveis.', null, 39.90, null, 'aguac.jpg', 1),
('sk2', 'skin-care', 'limpeza',    'Gel de Limpeza Facial', 'Gel com ceramidas e ácido hialurônico que limpa profundamente e controla a oleosidade sem agredir a barreira da pele.', null, 42.90, null, 'cerave.jpg', 2),
('sk3', 'skin-care', 'tratamento', 'mixsoon Bean Essence 50ml', 'Essência de soja fermentada que esfolia levemente, renova a textura da pele e deixa o rosto luminoso e uniforme.', null, 103.90, null, 'mixsoon.jpg', 3),
('sk4', 'skin-care', 'tratamento', 'medicube deep vitamin C', 'Sérum com vitamina C que clareia manchas, uniformiza o tom e combate a opacidade, devolvendo o viço à pele.', null, 116.90, null, 'vitamina.jpg', 4),
('sk5', 'skin-care', 'tratamento', 'serum madagascar centella tone', 'Sérum com centella asiática que acalma a pele, reduz vermelhidões e ajuda a uniformizar e iluminar o tom.', null, 125.90, null, 'tonee.jpg', 5),
('sk6', 'skin-care', 'hidratacao', 'Hidratante Facial Ácido Hialurônico', 'Hidratante leve com ácido hialurônico que retém água na pele, suaviza linhas finas e deixa o rosto macio e viçoso.', null, 84.90, null, 'hidrafacial.jpg', 6),
('sk7', 'skin-care', 'hidratacao', 'Creme Noturno Regenerador', 'Creme de textura rica que age durante o sono, regenerando e nutrindo a pele para um despertar com aspecto descansado.', null, 97.90, null, 'hidranoite.jpg', 7),
('sk8', 'skin-care', 'protecao',   'Protetor Solar Facial La Roche-Posay FPS 80 Incolor 40g', 'Proteção altíssima contra raios UVA e UVB, com textura leve e incolor que não deixa a pele branca. Previne manchas e envelhecimento.', null, 94.90, null, 'protetor.jpg', 8),
-- MAQUIAGEM
('maq1', 'maquiagem', 'rosto',  'Base Líquida MAC Matte', 'Base de alta cobertura com acabamento matte e controle de oleosidade por até 24 horas.', null, 249.90, null, 'mac.jpg', 1),
('maq2', 'maquiagem', 'rosto',  'Pó Compacto Ollie Ultrafino FPS 50', 'Pó compacto ultrafino com proteção solar FPS 50 e toque seco, ideal para o dia a dia.', null, 119.90, null, 'po.jpg', 2),
('maq3', 'maquiagem', 'rosto',  'Blush Cremoso Rosé', 'Blush de textura cremosa que se funde à pele e deixa um efeito natural de bochechas coradas.', null, 47.90, null, 'blush_dailus.jpg', 3),
('maq4', 'maquiagem', 'olhos',  'Paleta de Sombras Terracota', 'Paleta com tons terrosos matte e cintilantes, altamente pigmentados e fáceis de esfumar.', null, 119.90, null, '15371596152-bm-600-paleta-sombra-img03-af01.jpg', 4),
('maq5', 'maquiagem', 'olhos',  'Máscara de Cílios Volume XL', 'Máscara que aumenta o volume e separa os cílios, sem grumos e com longa duração.', null, 54.90, null, '3073-3420-3419-mascara-cilios-quadrada-14ml-detalhejpg-m0M6dZJeBpTsAcRJBS9r.jpeg', 5),
('maq6', 'maquiagem', 'olhos',  'Delineador Líquido Preto Intenso', 'Delineador com ponta precisa, preto intenso e secagem rápida, resistente à água.', null, 39.90, null, 'delineador.jpg', 6),
('maq7', 'maquiagem', 'labios', 'Lip Gloss Rhode Jelly Bean', 'Gloss de brilho espelhado com textura confortável e hidratação para os lábios.', null, 261.90, null, 'rhode.jpg', 7),
('maq8', 'maquiagem', 'labios', 'Batom Matte Longa Duração', 'Batom matte de alta pigmentação e longa duração, com acabamento aveludado.', null, 44.90, null, 'batommatte.jpg', 8),
-- CABELOS
('cab1', 'cabelos', 'shampoo',       'Shampoo Nutrição Profunda', 'Limpa suavemente enquanto nutre os fios com óleos vegetais, devolvendo maciez e brilho a cabelos secos.', null, 20.90, null, 'shampoo.jpg', 1),
('cab2', 'cabelos', 'shampoo',       'Shampoo Anticaspa Mentol', 'Com mentol e ativos anticaspa, controla a descamação e a oleosidade e deixa uma sensação refrescante no couro cabeludo.', null, 30.90, null, 'clear.jpg', 2),
('cab3', 'cabelos', 'condicionador', 'Condicionador Reconstrução', 'Repõe a massa capilar e fortalece os fios danificados por química e calor, reduzindo a quebra.', null, 222.90, null, 'keras.jpg', 3),
('cab4', 'cabelos', 'condicionador', 'Condicionador Hidratação Intensa', 'Hidrata intensamente, desembaraça e sela as cutículas, deixando os fios macios e fáceis de pentear.', null, 40.90, null, 'men.jpg', 4),
('cab5', 'cabelos', 'mascara',       'Máscara Capilar Seda Líquida', 'Tratamento intensivo que envolve os fios em uma película sedosa, devolvendo brilho, maleabilidade e toque macio.', null, 29.90, null, 'seda.jpg', 5),
('cab6', 'cabelos', 'mascara',       'Máscara Reparadora Pontas Duplas', 'Repara as pontas duplas e sela as extremidades, prevenindo novas quebras e deixando o comprimento mais saudável.', null, 64.90, null, 'ponta.jpg', 6),
('cab7', 'cabelos', 'oleo',          'Óleo Reparador Capilar', 'Óleo leve que nutre, protege do calor e repara os fios sem pesar, deixando o cabelo brilhante e disciplinado.', null, 74.90, null, 'oleo-reparador.jpg', 7),
('cab8', 'cabelos', 'oleo',          'Sérum Finalizador Anti-Frizz', 'Finalizador que controla o frizz e a umidade, alinha os fios e garante brilho e maciez o dia todo.', null, 58.90, null, 'serum-antifrizz.jpg', 8),
-- CORPO
('cor1', 'corpo', 'hidratante', 'Hidratante Corporal Manteiga de Karité', 'Com manteiga de karité, nutre profundamente a pele seca e forma uma barreira que mantém a hidratação por horas.', null, 54.90, null, 'karite.jpg', 1),
('cor2', 'corpo', 'hidratante', 'Hidratante Corporal de Amêndoas', 'Fórmula com óleo de amêndoas que acalma, hidrata e deixa a pele macia e perfumada.', null, 49.90, null, 'amendoas.jpg', 2),
('cor3', 'corpo', 'esfoliante', 'Esfoliante Corporal Açúcar & Coco', 'Grânulos de açúcar e óleo de coco removem células mortas enquanto hidratam, deixando a pele lisa e luminosa.', null, 44.90, null, 'esfoliante.jpg', 3),
('cor4', 'corpo', 'esfoliante', 'Esfoliante Corporal Café Detox', 'Esfoliante com grãos de café que ativa a circulação, renova a pele e ajuda a melhorar o aspecto da celulite.', null, 47.90, null, 'cremees.jpg', 4),
('cor5', 'corpo', 'oleo',       'Óleo Corporal Secante Rosa Mosqueta', 'Óleo de rosa mosqueta de rápida absorção que regenera a pele, ameniza marcas e estrias e não deixa sensação oleosa.', null, 62.90, null, 'rosamos.jpg', 5),
('cor6', 'corpo', 'oleo',       'Óleo Corporal Iluminador', 'Óleo com partículas iluminadoras que hidrata e deixa a pele com brilho dourado e acetinado.', null, 58.90, null, 'ilumi.jpg', 6),
('cor7', 'corpo', 'splash',     'Body Splash Rosa Branca', 'Fragrância leve e floral de rosa branca que refresca e perfuma o corpo com delicadeza ao longo do dia.', null, 39.90, null, 'body.jpg', 7),
('cor8', 'corpo', 'splash',     'Body Splash Baunilha & Âmbar', 'Fragrância quente e envolvente de baunilha com âmbar, que perfuma a pele com um toque doce e marcante.', null, 42.90, null, 'eudorabody.jpg', 8),
-- KITS
('kit1', 'kits', null, 'Kit Skin Care Madagascar', null, 'Ampoule Foam + Tônico Centella + Soothing Cream + Óleo de limpeza Centella Light + Centella Ampoule', 210.90, 259.40, 'kitskin.jpg', 1),
('kit2', 'kits', null, 'Kit Make Dia a Dia', null, 'Dior Addict Lip Glow 001 Pink + Dior Addict Lip Glow Oil 001 Pink', 629.00, 736.00, 'kitmakeup.jpg', 2),
('kit3', 'kits', null, 'Kit Cabelos Nutrição Profunda', null, 'Shampoo + máscara capilar + condicionador', 275.66, 358.00, 'kerastase.jpg', 3),
('kit4', 'kits', null, 'Kit Corpo Hidratação Total', null, 'loção corporal + body splash + sabonete + óleo corporal + esfoliante corporal', 452.30, 534.30, 'nativa.jpg', 4),
('kit5', 'kits', null, 'Kit Proteção Solar', null, 'Protetor solar facial + protetor solar corporal', 149.90, 189.80, 'protetores.jpg', 5),
-- PROMOÇÕES
('promo1', 'promocoes', 'skin-care', 'mixsoon Bean Essence 50ml', 'Essência de soja fermentada que esfolia levemente, renova a textura da pele e deixa o rosto luminoso e uniforme.', null, 79.90, 103.90, 'mixsoon.jpg', 1),
('promo2', 'promocoes', 'skin-care', 'medicube deep vitamin C', 'Sérum com vitamina C que clareia manchas, uniformiza o tom e combate a opacidade, devolvendo o viço à pele.', null, 89.90, 116.90, 'vitamina.jpg', 2),
('promo3', 'promocoes', 'maquiagem', 'lip gloss rhode Jelly Bean', 'Gloss de brilho espelhado com textura confortável e hidratação para os lábios.', null, 199.90, 261.90, 'rhode.jpg', 3),
('promo4', 'promocoes', 'skin-care', 'serum madagascar centella tone', 'Sérum com centella asiática que acalma a pele, reduz vermelhidões e ajuda a uniformizar e iluminar o tom.', null, 94.90, 125.90, 'tonee.jpg', 4),
('promo5', 'promocoes', 'skin-care', 'Protetor Solar La Roche-Posay FPS 80', 'Proteção altíssima contra raios UVA e UVB, com textura leve e incolor que não deixa a pele branca. Previne manchas e envelhecimento.', null, 69.90, 94.90, 'protetor.jpg', 5),
-- PÁGINA INICIAL: PRODUTOS (destaques)
('dest1', 'destaques', null, 'mixsoon Bean Essence 50ml', 'Essência de soja fermentada que esfolia levemente, renova a textura da pele e deixa o rosto luminoso e uniforme.', null, 103.90, null, 'mixsoon.jpg', 1),
('dest2', 'destaques', null, 'medicube deep vitamin C', 'Sérum com vitamina C que clareia manchas, uniformiza o tom e combate a opacidade, devolvendo o viço à pele.', null, 116.90, null, 'vitamina.jpg', 2),
('dest3', 'destaques', null, 'lip gloss rhode Jelly Bean', 'Gloss de brilho espelhado com textura confortável e hidratação para os lábios.', null, 261.90, null, 'rhode.jpg', 3),
('dest4', 'destaques', null, 'serum madagascar centella tone 1000ml', 'Sérum com centella asiática que acalma a pele, reduz vermelhidões e ajuda a uniformizar e iluminar o tom.', null, 125.90, null, 'tonee.jpg', 4),
('dest5', 'destaques', null, 'Protetor Solar Facial La Roche-Posay FPS 80 Incolor 40g', 'Proteção altíssima contra raios UVA e UVB, com textura leve e incolor que não deixa a pele branca. Previne manchas e envelhecimento.', null, 94.90, null, 'protetor.jpg', 5),
-- PÁGINA INICIAL: MAIS VENDIDOS
('mv1', 'mais-vendidos', null, 'Água Micelar Garnier', 'Remove maquiagem e impurezas sem precisar enxaguar. Fórmula suave que limpa sem ressecar, ideal para peles sensíveis.', null, 49.90, null, 'aguac.jpg', 1),
('mv2', 'mais-vendidos', null, 'Shampoo Kérastase Nutrição', 'Shampoo nutritivo que limpa suavemente e deixa os fios secos macios, brilhantes e mais fáceis de pentear.', null, 109.90, null, 'kera.jpg', 2),
('mv4', 'mais-vendidos', null, 'Hidratante Facial Manteiga de Karité', 'Hidratante com manteiga de karité que nutre profundamente e deixa a pele com toque macio e aveludado.', null, 34.90, null, 'prin.jpg', 3)
on conflict (id) do nothing;
