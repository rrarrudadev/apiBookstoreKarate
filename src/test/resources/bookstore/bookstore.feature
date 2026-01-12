Feature: BookStore endpoints (GET, POST, PUT)

  Background:
    * def baseUrl = karate.get('baseUrl')
    * def auth = karate.get('auth')
    * def authHeader = { Authorization: '#("Bearer " + auth.token)' }

  Scenario Outline: [SUCESSO] Listar catálogo de livros e Listar catálogo de livros com ISBN dinâmico
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

    Examples:
      | case |
      | ok   |

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

  Scenario Outline: [SUCESSO] Adicionar livro ao usuário com ISBN dinâmico

  # Criando usuário temporário (evita ISBN duplicado)
    * def temp = call read('classpath:auth/auth.feature')
    * def tempAuth = temp.auth
    * def tempHeader = { Authorization: '#("Bearer " + tempAuth.token)' }

  # Pega o ISBN dinâmicamente
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

    Examples:
      | case |
      | ok   |

  Scenario Outline: [FALHA] Adicionar ao usuário um livro com o ISBN duplicado na coleção
  # usuário temporário
    * def temp = call read('classpath:auth/auth.feature')
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

  # cleanup do usuário temporário
    Given url baseUrl
    And path '/Account/v1/User', tempAuth.userId
    And headers tempHeader
    When method delete
    Then status 204

    Examples:
      | case |
      | dup  |

  Scenario Outline: [SUCESSO] Trocar o ISBN de um livro
  # usuário temporário
    * def temp = call read('classpath:auth/auth.feature')
    * def tempAuth = temp.auth
    * def tempHeader = { Authorization: '#("Bearer " + tempAuth.token)' }

  # pega 2 ISBNs
    Given url baseUrl
    And path '/BookStore/v1/Books'
    When method get
    Then status 200
    * def oldIsbn = response.books[0].isbn
    * def newIsbn = response.books[1].isbn

  # adiciona oldIsbn
    Given url baseUrl
    And path '/BookStore/v1/Books'
    And headers tempHeader
    And request { userId: '#(tempAuth.userId)', collectionOfIsbns: [ { isbn: '#(oldIsbn)' } ] }
    When method post
    Then status 201

  # troca old -> new
    Given url baseUrl
    And path '/BookStore/v1/Books', oldIsbn
    And headers tempHeader
    And request { userId: '#(tempAuth.userId)', isbn: '#(newIsbn)' }
    When method put
    Then status 200
    And match response contains read('classpath:schema/bookstore-user.json')
    And match response.books[*].isbn contains newIsbn

  # cleanup do usuário temporário
    Given url baseUrl
    And path '/Account/v1/User', tempAuth.userId
    And headers tempHeader
    When method delete
    Then status 204

    Examples:
      | case |
      | ok   |

  Scenario Outline: [FALHA] Tentar trocar o ISBN antigo para um novo inválido
  # usuário temporário
    * def temp = call read('classpath:auth/auth.feature')
    * def tempAuth = temp.auth
    * def tempHeader = { Authorization: '#("Bearer " + tempAuth.token)' }

  # pega 1 ISBN válido e define em "old"
    Given url baseUrl
    And path '/BookStore/v1/Books'
    When method get
    Then status 200
    * def oldIsbn = response.books[0].isbn

  # adiciona oldIsbn
    Given url baseUrl
    And path '/BookStore/v1/Books'
    And headers tempHeader
    And request { userId: '#(tempAuth.userId)', collectionOfIsbns: [ { isbn: '#(oldIsbn)' } ] }
    When method post
    Then status 201

  # tenta trocar para um ISBN inválido
    Given url baseUrl
    And path '/BookStore/v1/Books', oldIsbn
    And headers tempHeader
    And request { userId: '#(tempAuth.userId)', isbn: '<invalidNewIsbn>' }
    When method put
    Then status <status>
    And match response contains read('classpath:schema/error-code-message.json')

  # cleanup do usuário temporário
    Given url baseUrl
    And path '/Account/v1/User', tempAuth.userId
    And headers tempHeader
    When method delete
    Then status 204

    Examples:
      | invalidNewIsbn | status |
      | INVALID_ISBN   | 400    |