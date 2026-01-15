Feature: Auth helper (cria usuário e gera token uma vez)
  Background:
    * def baseUrl = baseUrl

  Scenario: Criar usuário e gerar token
    * def rand = java.util.UUID.randomUUID() + ''
    * def userName = 'user_' + rand
    * def password = 'Test@@123A1!'

    #1º Cria Usuário
    Given url baseUrl
    And path '/Account/v1/User'
    And request { userName: '#(userName)', password: '#(password)' }
    When method post
    Then status 201
    * def userId = response.userID

    #2º Gera Token
    Given url baseUrl
    And path '/Account/v1/GenerateToken'
    And request { userName: '#(userName)', password: '#(password)' }
    When method post
    Then status 200
    And match response.token == '#string'
    * def token = response.token

    #3º Montar e disponibilizar auth
    * def auth =
      """
      {
        userId: "#(userId)",
        token: "#(token)",
        username: "#(userName)",
        password: "#(password)"

      }
      """

    * karate.set('auth', auth)
    * def result = { auth: auth }
    * return result