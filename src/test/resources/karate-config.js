function fn() {
    var config = { baseUrl: 'https://bookstore.demoqa.com' };

    karate.configure('logPrettyRequest', true);
    karate.configure('logPrettyResponse', true);

    // cria user + token UMA vez por execução da suíte
    var result = karate.callSingle('classpath:auth/auth.feature', { baseUrl: config.baseUrl });

    // proteção se caso algo mude no retorno
    config.auth = result.auth;

    return config;
}
