// ==========================================================
// CONEXÃO COM O SUPABASE (usado por todas as páginas)
// ==========================================================
const SUPABASE_URL = 'https://vdzqngqajtwwdteigfbj.supabase.co';
const SUPABASE_KEY = 'sb_publishable_2sv5Dd2O03kizGPyScKhSg_teNe4_qZ';

const db = window.supabase.createClient(SUPABASE_URL, SUPABASE_KEY);

// Traduz as mensagens de erro mais comuns do Supabase
function traduzirErro(mensagem) {
    const m = (mensagem || '').toLowerCase();
    if (m.includes('invalid login credentials')) return 'E-mail ou senha incorretos.';
    if (m.includes('already registered')) return 'Este e-mail já está cadastrado.';
    if (m.includes('password should be at least')) return 'A senha precisa ter pelo menos 6 caracteres.';
    if (m.includes('email not confirmed')) return 'Confirme seu e-mail antes de entrar (veja sua caixa de entrada).';
    if (m.includes('invalid') && m.includes('email')) return 'Digite um e-mail válido.';
    if (m.includes('rate limit')) return 'Muitas tentativas. Aguarde alguns minutos e tente de novo.';
    return 'Ocorreu um erro: ' + mensagem;
}

// ==========================================================
// ÍCONES (em vez de emojis) — use: icone('carrinho')
// ==========================================================
const ICONES = {
    carrinho: '<circle cx="8" cy="21" r="1"/><circle cx="19" cy="21" r="1"/><path d="M2.05 2.05h2l2.66 12.42a2 2 0 0 0 2 1.58h9.78a2 2 0 0 0 1.95-1.57l1.65-7.43H5.12"/>',
    pacote: '<path d="m7.5 4.27 9 5.15"/><path d="M21 8a2 2 0 0 0-1-1.73l-7-4a2 2 0 0 0-2 0l-7 4A2 2 0 0 0 3 8v8a2 2 0 0 0 1 1.73l7 4a2 2 0 0 0 2 0l7-4A2 2 0 0 0 21 16Z"/><path d="m3.3 7 8.7 5 8.7-5"/><path d="M12 22V12"/>',
    cartao: '<rect width="20" height="14" x="2" y="5" rx="2"/><line x1="2" x2="22" y1="10" y2="10"/>',
    celular: '<rect width="14" height="20" x="5" y="2" rx="2"/><path d="M12 18h.01"/>',
    boleto: '<path d="M3 5v14"/><path d="M8 5v14"/><path d="M12 5v14"/><path d="M17 5v14"/><path d="M21 5v14"/>',
    raio: '<path d="M13 2 3 14h9l-1 8 10-12h-9l1-8z"/>',
    relogio: '<circle cx="12" cy="12" r="10"/><polyline points="12 6 12 12 16 14"/>',
    caminhao: '<path d="M14 18V6a2 2 0 0 0-2-2H4a2 2 0 0 0-2 2v11a1 1 0 0 0 1 1h2"/><path d="M15 18H9"/><path d="M19 18h2a1 1 0 0 0 1-1v-3.65a1 1 0 0 0-.22-.624l-3.48-4.35A1 1 0 0 0 17.52 8H14"/><circle cx="17" cy="18" r="2"/><circle cx="7" cy="18" r="2"/>',
    sacola: '<path d="M6 2 3 6v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2V6l-3-4Z"/><path d="M3 6h18"/><path d="M16 10a4 4 0 0 1-8 0"/>',
    coracao: '<path d="M19 14c1.49-1.46 3-3.21 3-5.5A5.5 5.5 0 0 0 16.5 3c-1.76 0-3 .5-4.5 2-1.5-1.5-2.74-2-4.5-2A5.5 5.5 0 0 0 2 8.5c0 2.3 1.5 4.05 3 5.5l7 7Z"/>',
    check: '<circle cx="12" cy="12" r="10"/><path d="m9 12 2 2 4-4"/>',
    email: '<rect width="20" height="16" x="2" y="4" rx="2"/><path d="m22 7-8.97 5.7a1.94 1.94 0 0 1-2.06 0L2 7"/>',
    local: '<path d="M20 10c0 6-8 12-8 12s-8-6-8-12a8 8 0 0 1 16 0Z"/><circle cx="12" cy="10" r="3"/>'
};

function icone(nome, tamanho = 18) {
    return `<svg class="icone" width="${tamanho}" height="${tamanho}" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" style="vertical-align:middle;flex-shrink:0">${ICONES[nome] || ''}</svg>`;
}

// ==========================================================
// CONTADOR DO CARRINHO (bolinha no ícone do cabeçalho)
// Chame atualizarContadorCarrinho() sempre que o carrinho mudar
// ==========================================================
function atualizarContadorCarrinho() {
    const badge = document.getElementById('cart-badge');
    if (!badge) return;
    const carrinho = JSON.parse(localStorage.getItem('carrinho')) || [];
    const total = carrinho.reduce((soma, item) => soma + item.quantidade, 0);
    badge.textContent = total > 0 ? (total > 99 ? '99+' : total) : '';
}

// Pega o nome salvo no cadastro (ou o começo do e-mail, se não tiver)
function nomeDoUsuario(user) {
    return (user.user_metadata && user.user_metadata.nome) || user.email.split('@')[0];
}

// ==========================================================
// MENU DO CABEÇALHO
// - Deslogada: mostra "Cadastrar" e "Login" + ícone de usuário
// - Logada: esconde "Cadastrar" e "Login" e mostra a área do usuário
// ==========================================================
function atualizarMenu(user) {
    const linkCadastrar = document.getElementById('link-cadastrar');
    const linkLogin = document.getElementById('link-login');
    const area = document.getElementById('area-usuario');

    // Página SEM a área de usuário: mantém o comportamento antigo (Olá, nome / Sair)
    if (!area) {
        if (!linkCadastrar || !linkLogin || !user) return;
        linkCadastrar.textContent = 'Olá, ' + nomeDoUsuario(user).split(' ')[0];
        linkCadastrar.href = '#';
        linkLogin.textContent = 'Sair';
        linkLogin.href = '#';
        linkLogin.onclick = async (e) => {
            e.preventDefault();
            await db.auth.signOut();
            window.location.href = 'index.html';
        };
        return;
    }

    // Mostra/esconde "Cadastrar" e "Login"
    if (linkCadastrar) linkCadastrar.parentElement.style.display = user ? 'none' : '';
    if (linkLogin) linkLogin.parentElement.style.display = user ? 'none' : '';

    area.classList.toggle('logado', !!user);
    area.classList.remove('aberto');

    if (!user) return;

    // Preenche os dados do usuário
    const nome = nomeDoUsuario(user);
    const inicial = nome.trim().charAt(0) || '?';

    document.getElementById('usuario-avatar').textContent = inicial;
    document.getElementById('usuario-avatar-grande').textContent = inicial;
    document.getElementById('usuario-nome-curto').textContent = nome.split(' ')[0];
    document.getElementById('usuario-nome-completo').textContent = nome;
    document.getElementById('usuario-email').textContent = user.email;

    const desde = document.getElementById('usuario-desde');
    if (desde && user.created_at) {
        const data = new Date(user.created_at).toLocaleDateString('pt-BR', { month: 'long', year: 'numeric' });
        desde.textContent = 'Cliente desde ' + data;
    }
}

// Liga os cliques da área do usuário (abrir menu, fechar, sair)
function prepararAreaUsuario() {
    const area = document.getElementById('area-usuario');
    if (!area) return;

    const botao = document.getElementById('usuario-botao');
    const sair = document.getElementById('usuario-sair');

    botao.addEventListener('click', (e) => {
        e.stopPropagation();
        // Deslogada: o ícone leva para o login
        if (!area.classList.contains('logado')) {
            window.location.href = 'login.html';
            return;
        }
        area.classList.toggle('aberto');
    });

    // Clicar fora fecha o menu
    document.addEventListener('click', (e) => {
        if (!area.contains(e.target)) area.classList.remove('aberto');
    });

    // Tecla Esc fecha o menu
    document.addEventListener('keydown', (e) => {
        if (e.key === 'Escape') area.classList.remove('aberto');
    });

    sair.addEventListener('click', async () => {
        await db.auth.signOut();
        window.location.href = 'index.html';
    });
}

document.addEventListener('DOMContentLoaded', async () => {
    prepararAreaUsuario();
    atualizarContadorCarrinho();

    const { data: { session } } = await db.auth.getSession();
    atualizarMenu(session ? session.user : null);

    // Atualiza sozinho quando a pessoa entra, sai ou se cadastra
    db.auth.onAuthStateChange((_evento, session) => {
        atualizarMenu(session ? session.user : null);
    });
});
