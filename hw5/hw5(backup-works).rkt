#lang racket



;(define my_binding (get-lambda-bindings '(lambda (a b g) f a b)  '(lambda (a c z) f a c)  '()))
;(find-mapping 't my_binding)
(define (find-mapping expr bindings)
  (cond
    [(equal? '() bindings) '()]
    [(equal? expr (car (car bindings))) (cdr (car bindings))]
    [else (find-mapping expr (cdr bindings))]
  )
)

;given symbol, translates using bindings
;if it cannot be translated, symbol itself is returned
(define (trans-expr expr bindings)
(let ([tr-sym (find-mapping expr bindings)])
  (if (equal? tr-sym '()) expr tr-sym))
)

;given a lambda expr, translates formal and body of lambda expr 
(define (trans-lambda lambda-expr bindings)
  ;;CHANGED 'append' to 'cons'
;(append (list (car lambda-expr)) (trans-body (car(cdr lambda-expr)) bindings) (trans-body (cdr(cdr lambda-expr)) bindings))
(cond [(equal? '() bindings) lambda-expr])
(cons (car lambda-expr) (cons (trans-body (car(cdr lambda-expr)) bindings) (cons (trans-body (cdr(cdr lambda-expr)) bindings) '() )))
)

(define (trans-body body bindings)
 (cond
  [(equal? '() body) '()]
   ;able to translate entire body 
  [(not (equal? (trans-expr body bindings) body)) (trans-expr body bindings)]
  ;not a pair
  [(not (pair? body)) (trans-expr body bindings)];'list' removed
  [(and (list? body) (equal? 1 (length body))) ;;ADDED
   (trans-body (car body) bindings)
  ]

   ;;CHANGED 'append' to 'cons'
  [else (cons (trans-expr (car body) bindings) (trans-body (cdr body) bindings))];;'list' removed
 )
)

(define (get-lambda-bindings x y curr_bindings)
  (get-lambda-bindings-helper (car (cdr x))  (car (cdr y)) curr_bindings)
)

;given two lambda FORMALS, return list of 3 lists (bindings list 
;first list has symbols from x formal
;second list has symbols from y formal
;third list is combination of them ;;symbols agreed upon are not included
(define (get-lambda-bindings-helper x y curr_bindings)
  ;they cannot be mapped to each other 
  (cond

        [(equal? x y) curr_bindings]

        ;the lambda formals are not equal and are just single values
        [(and (not (pair? y)) (not (pair? y))) (add-to-bindings x y curr_bindings)]

        ;the lambda formals have unequal lengths 
        [(and (and (pair? x) (pair? y)) (not (equal? (length x) (length y)))) '()]

        ;current part of lambda formals are equal, find lambda bindings of rest 
        [(equal? (car x) (car y)) (get-lambda-bindings-helper (cdr x) (cdr y) curr_bindings)]

        ;create binding, (car x) != (car y) 
        [else (get-lambda-bindings-helper (cdr x) (cdr y) (add-to-bindings (car x) (car y) curr_bindings))] 
  )
)




;given two lists of terms 
;binds two terms to make symbol x!y 
;(define (bind x y)
;(string->symbol (string-append (symbol->string x) "!" (symbol->string y))))

(define (bind x y)
(string->symbol (string-append (symbol->string x) "!" (symbol->string y))))


;;given (expr-compare '((lambda (a) a) c) '((lambda (b) b) d))
;;for x, makes: ((a) a !b) for y, makes: ((b)(a!b))
;(define old_bindings (create-binding 'b 'c))
;(define new_bindings (create-binding 'd 'f))

;given create-binding-x 'a 'b makes (a a!b)  
(define (create-binding-x x y)
  (append (list x) (list (bind x y))))
;given create-binding-y 'a 'b makes (b a!b)  
(define (create-binding-y x y)
  (append (list y) (list (bind x y))))


;takes two individual binding lists and puts into one 
;for x: (a a!b) ;for y:(b a!b) -> ((a a!b) (b a!b))
(define (create-combined-binding x-bind y-bind)
  (list (create-binding-x x-bind y-bind) (create-binding-y x-bind y-bind))
)


;given current list of bindings add x to first list, y to 2nd list, x!y to third list 
(define (add-to-bindings x y bindings)
  ;bindings is empty, make initial list 
  (cond
  [(equal? '() bindings) (create-combined-binding x y)] ;create bindings for x and y and put in list
  ;add to list
  [else (append bindings (create-combined-binding x y))] 
))

(define (is-lambda expr)
(cond
 [(not(pair? expr)) #f]
 [(equal? 'lambda (car expr)) #t]
 [(equal? 'λ (car expr)) #t]
 [else #f])
  
)
(define (tostring var) (symbol->string var))

;does expr-compare processing on JUST lambda expression
;'(lambda a a) is good input
;'((lambda (a) (f a)) 1)-> '(lambda (a) (f a))

;test '(lambda a a) '(lambda b b)
; test '(lambda (a b) (f a b)) '(lambda (a c) (f a c))
(define (expr-compare-lambda lambda-x lambda-y)
       (cond
       [(equal? lambda-x lambda-y) lambda-x]
       ;[equal? ]
       ;one arg param is a pair while other isn't 
       [(or (and (pair? lambda-x) (not (pair? lambda-y))) (and (pair? lambda-y) (not (pair? lambda-x))))(list 'if '% lambda-x lambda-y)];;removed 'list'
       ;diff arg list length
       [(not(equal? (length (cdr lambda-x)) (length (cdr lambda-y)))) (list 'if '% lambda-x lambda-y)]

       ;both just have one argument 
       ;[(and (not (pair? (car (cdr lambda-x)))) (not (pair? (car (cdr lambda-y))))) ]

       [(or (and (list? (car (cdr lambda-x))) (not (list? (car(cdr lambda-y))))) (and (list? (car(cdr lambda-y))) (not (list? (car(cdr lambda-x)))))) (list 'if '% lambda-x lambda-y)]
       
       ;they have different argument lengths (**check that the arg param is actually a list before checking its length)
       [(and (and(pair? (car (cdr lambda-x))) (pair? (car (cdr lambda-y))))  (or(not(equal? (length (car (cdr lambda-x))) (length (car (cdr lambda-y))))))) (list 'if '% lambda-x lambda-y)];;removed list 

       ;create bindings for the lambdas 
       ;[else (let ([lambda-bindings (get-lambda-bindings (car x) (car y) '())])
       [else (let ([lambda-bindings (get-lambda-bindings  lambda-x lambda-y '())])
               
               ;we can't translate anything, so compare the lambdas as if they were strings
               ;;you might be causing infinite loop here

               (cond [(equal? lambda-bindings '()) (if (or (equal? 'λ (car lambda-x)) (equal? 'λ (car lambda-y))) (cons 'λ (expr-compare (cdr lambda-x) (cdr lambda-y))) 
                                                       (cons 'lambda (expr-compare (cdr lambda-x) (cdr lambda-y))))  ];;ADDED cons
                     [else (expr-compare (trans-lambda lambda-x lambda-bindings) (trans-lambda lambda-y lambda-bindings))]) ;;removed 'list'


       )
           
       ]
     )
)

(define (expr-compare x y)
  (cond
    [(equal? x y) x];if equal return either

    ;equate to λ if one used λ  and one used lambda 
    [(or (and (equal? x 'λ) (equal? y 'lambda)) (and (equal? y 'λ) (equal? x 'lambda))) 'λ]
    
    ;not equal and both integers
    [(and (not(equal? x y))(and (integer? x)(integer? y))) (list 'if '% x y)]
    ;both are just booleans
    [(and (not (equal? x y)) (and (boolean? x) (boolean? y))) (if x '% '(not %))]

    ;one not a pair and not equal 
    [(or (not (pair? x)) (not (pair? y))) (list 'if '% x y)]

    ;DO NOT USE THIS [(or (equal? 1 (length x)) (equal? 1 (length y))) (list 'if '% x y)]
    
    ;;quote case
    [(or (equal? 'quote (car x)) (equal? 'quote (car y))) (list 'if '% x y)]
    ;only one has if
    [(or (and (equal? (car x) 'if) (not(equal? (car y) 'if))) (and (equal? (car y) 'if) (not(equal? (car x) 'if))))(list 'if '% x y) ]
    
    ;both lists that are not equal ;;takenout: (not (equal? (length x) (length y))))
    [(and (and(list? x) (list? y)) (not (equal? (length x) (length y))))  (list 'if '% x y)]    


    ;entirety of expressions are lambdas, process them as lambdas,
    [(and (is-lambda x) (is-lambda y))
     (expr-compare-lambda x y)]
    ;(car expr) are lambdas, process those as lambdas, recursively pass those into expr-compare, and append with expr-compare on (cdr expr) 
    [(and (is-lambda (car x)) (is-lambda (car y)))
     ;;CHANGED 'append' to 'cons'
     (cons (expr-compare-lambda (car x) (car y)) (expr-compare (cdr x) (cdr y)))
    ]

    ;lists of equal lengths but different contents
    [(and (and (list? x) (list? y)) (and (equal? (length x) (length y ))))
     (cons (expr-compare (car x) (car y)) (expr-compare (cdr x)(cdr y)) )
    ]
    
    ;recursive call
    [else (cons (expr-compare (car x) (car y)) (expr-compare (cdr x) (cdr y)) )]
  )


 )


  
 