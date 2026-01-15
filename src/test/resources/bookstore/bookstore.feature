Feature: BookStore endpoints (GET, POST, PUT)

  Background:
    * def baseUrl = karate.get('baseUrl')
    * def auth = karate.get('auth')
    * def authHeader = { Authorization: '#("Bearer " + auth.token)' }

  Scenario: [SUCESSO] Listar catálogo de livros e buscar livro com ISBN dinâmico
  # GET Books
    Given url baseUrl
    And path '/BookStore/v1/Books'
    When method get
    Then status 200
    And match response == read('classpath:schema/bookstore-books.json')
    And match response.books[0] contains read('classpath:schema/bookstore-book.json')
    * def firstIsbn = response.books[0].isbn

  # GET Book com ISBN dinâmico
    Given url baseUrl
    And path '/BookStore/v1/Book'
    And param ISBN = firstIsbn
    When method get
    Then status 200
    And match response contains read('classpath:schema/bookstore-book.json')
    And match response.isbn == firstIsbn

  Scenario Outline: [FALHA] Listar livro com ISBN inválido
    Given url baseUrl
    And path '/BookStore/v1/Book'
    And param ISBN = '<isbn>'
    When method get
    Then status <status>
    And match response contains read('classpath:schema/error-code-message.json')

    Examples:
      | isbn         | status |
      | INVALID_ISBN | 400    |

  Scenario: [SUCESSO] Adicionar livro ao usuário com ISBN dinâmico
  # Usuário temporário (evita afetar auth principal do karate-config)
    * def temp = call read('classpath:auth/auth.feature') { baseUrl: '#(baseUrl)' }
    * def tempAuth = temp.auth
    * def tempHeader = { Authorization: '#("Bearer " + tempAuth.token)' }

  # Pega o ISBN dinamicamente
    Given url baseUrl
    And path '/BookStore/v1/Books'
    When method get
    Then status 200
    * def firstIsbn = response.books[0].isbn

  # Adiciona livro ao usuário
    Given url baseUrl
    And path '/BookStore/v1/Books'
    And headers tempHeader
    And request { userId: '#(tempAuth.userId)', collectionOfIsbns: [ { isbn: '#(firstIsbn)' } ] }
    When method post
    Then status 201
    And match response contains read('classpath:schema/bookstore-user.json')
    And match response.books[0].isbn == firstIsbn

  # Cleanup do usuário temporário
    Given url baseUrl
    And path '/Account/v1/User', tempAuth.userId
    And headers tempHeader
    When method delete
    Then status 204

  Scenario: [FALHA] Adicionar ao usuário um livro com o ISBN duplicado na coleção
  # Usuário temporário
    * def temp = call read('classpath:auth/auth.feature') { baseUrl: '#(baseUrl)' }
    * def tempAuth = temp.auth
    * def tempHeader = { Authorization: '#("Bearer " + tempAuth.token)' }

  # ISBN dinâmico
    Given url baseUrl
    And path '/BookStore/v1/Books'
    When method get
    Then status 200
    * def firstIsbn = response.books[0].isbn

  # 1ª vez (setup) -> deve funcionar
    Given url baseUrl
    And path '/BookStore/v1/Books'
    And headers tempHeader
    And request { userId: '#(tempAuth.userId)', collectionOfIsbns: [ { isbn: '#(firstIsbn)' } ] }
    When method post
    Then status 201

  # 2ª vez (duplicado) -> deve falhar
    Given url baseUrl
    And path '/BookStore/v1/Books'
    And headers tempHeader
    And request { userId: '#(tempAuth.userId)', collectionOfIsbns: [ { isbn: '#(firstIsbn)' } ] }
    When method post
    Then status 400
    And match response contains read('classpath:schema/error-code-message.json')
    And match response.message contains 'already'

  # Cleanup do usuário temporário
    Given url baseUrl
    And path '/Account/v1/User', tempAuth.userId
    And headers tempHeader
    When method delete
    Then status 204

  Scenario: [SUCESSO] Trocar o ISBN de um livro
  # Usuário temporário
    * def temp = call read('classpath:auth/auth.feature') { baseUrl: '#(baseUrl)' }
    * def tempAuth = temp.auth
    * def tempHeader = { Authorization: '#("Bearer " + tempAuth.token)' }

  # Pega 2 ISBNs
    Given url baseUrl
    And path '/BookStore/v1/Books'
    When method get
    Then status 200
    * def oldIsbn = response.books[0].isbn
    * def newIsbn = response.books[1].isbn

  # Adiciona oldIsbn
    Given url baseUrl
    And path '/BookStore/v1/Books'
    And headers tempHeader
    And request { userId: '#(tempAuth.userId)', collectionOfIsbns: [ { isbn: '#(oldIsbn)' } ] }
    When method post
    Then status 201

  # Troca old -> new
    Given url baseUrl
    And path '/BookStore/v1/Books', oldIsbn
    And headers tempHeader
    And request { userId: '#(tempAuth.userId)', isbn: '#(newIsbn)' }
    When method put
    Then status 200
    And match response contains read('classpath:schema/bookstore-user.json')
    And match response.books[*].isbn contains newIsbn

  # Cleanup do usuário temporário
    Given url baseUrl
    And path '/Account/v1/User', tempAuth.userId
    And headers tempHeader
    When method delete
    Then status 204

  Scenario Outline: [FALHA] Tentar trocar o ISBN antigo para um novo inválido
  # Usuário temporário
    * def temp = call read('classpath:auth/auth.feature') { baseUrl: '#(baseUrl)' }
    * def tempAuth = temp.auth
    * def tempHeader = { Authorization: '#("Bearer " + tempAuth.token)' }

  # Pega 1 ISBN válido e define em "old"
    Given url baseUrl
    And path '/BookStore/v1/Books'
    When method get
    Then status 200
    * def oldIsbn = response.books[0].isbn

  # Adiciona oldIsbn
    Given url baseUrl
    And path '/BookStore/v1/Books'
    And headers tempHeader
    And request { userId: '#(tempAuth.userId)', collectionOfIsbns: [ { isbn: '#(oldIsbn)' } ] }
    When method post
    Then status 201

  # Tenta trocar para um ISBN inválido
    Given url baseUrl
    And path '/BookStore/v1/Books', oldIsbn
    And headers tempHeader
    And request { userId: '#(tempAuth.userId)', isbn: '<invalidNewIsbn>' }
    When method put
    Then status <status>
    And match response contains read('classpath:schema/error-code-message.json')

  # Cleanup do usuário temporário
    Given url baseUrl
    And path '/Account/v1/User', tempAuth.userId
    And headers tempHeader
    When method delete
    Then status 204

    Examples:
      | invalidNewIsbn | status |
      | INVALID_ISBN   | 400    |
