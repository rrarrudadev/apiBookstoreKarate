Feature: Auth helper (cria usuário e gera token uma vez)

  Background:
  # baseUrl vem como argumento do callSingle no karate-config.js
    * def baseUrl = baseUrl

  Scenario: Criar usuário e gerar token
    * def rand = java.util.UUID.randomUUID() + ''
    * def userName = 'user_' + rand
    * def password = 'Test@@123A1!'

  # 1) Cria Usuário
    Given url baseUrl
    And path '/Account/v1/User'
    And request { userName: '#(userName)', password: '#(password)' }
    When method post
    Then status 201
    And match response.userID == '#string'
    * def userId = response.userID

  # 2) Gera Token
    Given url baseUrl
    And path '/Account/v1/GenerateToken'
    And request { userName: '#(userName)', password: '#(password)' }
    When method post
    Then status 200
    And match response.token == '#string'
    * def token = response.token

  # 3) Monta auth (essa variável é o que o karate-config vai pegar em result.auth)
    * def auth =
    """
    {
      userId: "#(userId)",
      token: "#(token)",
      username: "#(userName)",
      password: "#(password)"
    }
    """

  # Opcional, mas ok: deixa auth disponível no contexto dessa execução
    * karate.set('auth', auth)
