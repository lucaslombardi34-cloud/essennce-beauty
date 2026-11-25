// ==========================================================
// PRODUTOS VINDOS DO BANCO (tabela "produtos" do Supabase)
// Precisa do supabase.js carregado antes (usa o "db").
// ==========================================================

// Busca os produtos ativos de uma página (ex.: 'cabelos', 'kits', 'destaques')
// e devolve no mesmo formato que as páginas já usavam.
async function carregarProdutos(pagina) {
    const { data, error } = await db
        .from('produtos')
        .select('*')
        .eq('pagina', pagina)
        .eq('ativo', true)
        .order('ordem', { ascending: true })
        .order('criado_em', { ascending: true });

    if (error) {
        console.error('Erro ao carregar produtos:', error);
        return null;
    }

    return data.map(p => ({
        id: p.id,
        nome: p.nome,
        categoria: p.categoria,
        descricao: p.descricao,
        itensKit: p.itens_kit,
        preco: Number(p.preco),
        precoOriginal: p.preco_original != null ? Number(p.preco_original) : null,
        // usado pela página de promoções
        precoPromo: Number(p.preco),
        imagem: p.imagem
    }));
}

// Mensagem dentro da lista enquanto carrega / se der erro / se estiver vazia
function mensagemProdutos(container, texto) {
    container.innerHTML = `<p style="grid-column:1/-1;text-align:center;color:#777;padding:40px 0;">${texto}</p>`;
}

// Evita que um texto cadastrado quebre o HTML da página
function escaparHtml(texto) {
    return String(texto ?? '')
        .replace(/&/g, '&amp;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;')
        .replace(/"/g, '&quot;')
        .replace(/'/g, '&#39;');
}

function formatarPrecoBR(valor) {
    return 'R$ ' + Number(valor).toFixed(2).replace('.', ',');
}

// Card padrão de produto (com preço "de/por" se tiver preco_original)
function montarCardProduto(produto, { tag = 'desconto-tag' } = {}) {
    const card = document.createElement('div');
    card.className = 'product-card';
    card.dataset.id = produto.id;
    card.dataset.nome = produto.nome;
    card.dataset.preco = produto.preco;

    const temDesconto = produto.precoOriginal && produto.precoOriginal > produto.preco;
    const desconto = temDesconto ? Math.round(100 - (produto.preco / produto.precoOriginal) * 100) : 0;

    const texto = produto.itensKit
        ? `<p class="itens-kit">${escaparHtml(produto.itensKit)}</p>`
        : `<p class="descricao">${escaparHtml(produto.descricao)}</p>`;

    const precos = temDesconto
        ? `<div class="precos">
               <span class="price-old">${formatarPrecoBR(produto.precoOriginal)}</span>
               <span class="price">${formatarPrecoBR(produto.preco)}</span>
           </div>`
        : `<p class="price">${formatarPrecoBR(produto.preco)}</p>`;

    card.innerHTML = `
        ${temDesconto ? `<span class="${tag}">-${desconto}%</span>` : ''}
        <img src="${escaparHtml(produto.imagem)}" alt="${escaparHtml(produto.nome)}">
        <div class="product-info">
            <h3>${escaparHtml(produto.nome)}</h3>
            ${texto}
            ${precos}
            <button class="btn btn-comprar">Comprar</button>
            <button class="btn btn-adicionar">Adicionar</button>
        </div>
    `;
    return card;
}

// Estilos mínimos para preço "de/por" e etiqueta de desconto.
// Usa :where() (peso zero), então o CSS próprio de cada página continua valendo.
(function () {
    const css = `
        :where(.product-card) { position: relative; }
        :where(.product-card .precos) { display:flex; justify-content:center; align-items:baseline; gap:10px; margin-bottom:15px; }
        :where(.product-card .price-old) { color:#999; text-decoration:line-through; font-size:15px; }
        :where(.product-card .precos .price) { margin-bottom:0; }
        :where(.desconto-tag, .kit-tag) { position:absolute; top:15px; left:15px; background:#000; color:#fff;
            font-size:13px; font-weight:bold; padding:6px 12px; border-radius:20px; z-index:2; }
        :where(.product-card .itens-kit) { color:#777; font-size:14px; line-height:1.5; margin-bottom:15px; }
    `;
    const estilo = document.createElement('style');
    estilo.textContent = css;
    document.head.prepend(estilo);
})();
