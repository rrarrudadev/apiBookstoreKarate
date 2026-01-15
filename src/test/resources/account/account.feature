Feature: Account endpoints (User, GenerateToken, Delete User)

  Background:
    * def baseUrl = karate.get('baseUrl')
    * def auth = karate.get('auth')
    * def authHeader = { Authorization: '#("Bearer " + auth.token)' }

# Criar Usuário com sucesso

  Scenario Outline: [SUCESSO] Criar um usuário
    * def rand = java.util.UUID.randomUUID() + ''
    * def userName = 'user_' + rand

    Given url baseUrl
    And path '/Account/v1/User'
    And request { userName: '#(userName)', password: '<password>' }
    When method post
    Then status 201
    And match response == read('classpath:schema/account-user-success.json')

    Examples:
      | password       |
      | Test@@123A1!   |

# Tentar criar usuário sem preencher o campo da senha

  Scenario Outline: [FALHA] Criar usuário com payload inválido
    * def rand = java.util.UUID.randomUUID() + ''
    * def userName = 'bad_' + rand

    Given url baseUrl
    And path '/Account/v1/User'
    And request { userName: '#(userName)' }
    When method post
    Then status 400
    And match response == read('classpath:schema/account-error.json')

    Examples:
      | password           |
      | 'missing_password' |

# Gerar token com usuário e senha válidos

  Scenario Outline: [SUCESSO] Gerar token com credenciais válidas
    Given url baseUrl
    And path '/Account/v1/GenerateToken'
    And request { userName: '#(auth.username)', password: '#(auth.password)' }
    When method post
    Then status 200
    And match response == read('classpath:schema/token-success.json')

    Examples:
      | case |
      | 'ok' |

# Gerar token com usuário e senha inválidos

  Scenario Outline: [FALHA] Gerar token com credenciais inválidas
    Given url baseUrl
    And path '/Account/v1/GenerateToken'
    And request { userName: '#(auth.username)', password: '<password>' }
    When method post
    Then status 200
    And match response == read('classpath:schema/token-fail.json')
    And match response.status == 'Failed'

    Examples:
      | password         |
      | wrongPassword!1  |

 # Cria um usuário "temporário" só para ser deletado (não quebra o auth principal)

  Scenario Outline: [SUCESSO] Deletar um usuário
    * def temp = call read('classpath:auth/auth.feature') { baseUrl: '#(baseUrl)' }
    * def tempAuth = temp.auth
    * def tempHeader = { Authorization: '#("Bearer " + tempAuth.token)' }

    Given url baseUrl
    And path '/Account/v1/User', tempAuth.userId
    And headers tempHeader
    When method delete
    Then status 204

    Examples:
      | case |
      | 'ok' |

# Tentar Deletar um usuário sem o token

  Scenario Outline: [FALHA] Deletar um usuário sem o token
    Given url baseUrl
    And path '/Account/v1/User', auth.userId
    When method delete
    Then status 401
    And match response == read('classpath:schema/account-unauthorized.json')

    Examples:
      | case |
      | 'no_token' |
