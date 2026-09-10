/*
============================================================
[1장 2강] 실습문제: 실행계획(EXPLAIN) 읽는 법
============================================================

[실습 목표]
- EXPLAIN과 EXPLAIN ANALYZE의 차이를 구분할 수 있다.
- 실행계획에서 스캔 방식, cost, rows, actual rows, Execution Time을 확인할 수 있다.
- JOIN 실행계획을 아래쪽 노드부터 위쪽 노드 방향으로 읽을 수 있다.
- 각 노드의 예상 행 수와 실제 처리 행 수를 확인하고 의미를 설명할 수 있다.

[사용 환경]
- PostgreSQL
- DBeaver

[사용 데이터]
- customers : 50,000행
- orders : 300,000행
- order_items : 600,000행

[주요 관계]
- customers.customer_id = orders.customer_id
- orders.order_id = order_items.order_id

[주의사항]
- cost와 실행계획의 세부 형태는 PostgreSQL 환경에 따라 달라질 수 있습니다.
- 특정 cost 숫자나 특정 스캔 방식을 외우는 것이 아니라,
  자신의 실행계획에서 해당 항목을 찾아 해석하는 것이 중요합니다.
- 이번 강에서는 인덱스 생성이나 통계정보 갱신을 수행하지 않습니다.
*/


/*
============================================================
실습 준비. 데이터 규모 확인
============================================================
*/

SELECT COUNT(*) AS customer_count FROM customers;
SELECT COUNT(*) AS order_count FROM orders;
SELECT COUNT(*) AS order_item_count FROM order_items;


/*
============================================================
필수 1. EXPLAIN과 EXPLAIN ANALYZE 비교
============================================================

[문제 1-1]

[문제 설명]
order_id가 150000인 주문 한 건을 조회하고,
같은 SELECT문에 EXPLAIN과 EXPLAIN ANALYZE를 각각 적용하여
예상 실행계획과 실제 실행 결과를 비교하세요.

[요구사항]
1. orders 테이블에서 order_id = 150000인 주문을 조회하세요.
2. 같은 SELECT문에 EXPLAIN을 적용하세요.
3. 같은 SELECT문에 EXPLAIN ANALYZE를 적용하세요.
4. 실행계획에서 다음 항목을 확인해 기록하세요.
   - 스캔 방식: Seq Scan(full scan)
   - cost의 시작 비용: 0.00
   - cost의 총 비용: 6321.17
   - 예상 rows: 1
   - actual rows:1
   - Execution Time:32.177
5. 다음 질문에 답하세요.
   Q1. EXPLAIN ANALYZE에서 EXPLAIN보다 추가로 확인할 수 있는 정보는 무엇인가요?
   - actual rows, actual time, loops처럼 실제 실행 결과 및 Execution Time
   Q2. cost는 실제 실행 시간(ms)인가요?
   - ㄴㄴ cost는 옵티마이저가 실행계획 후보를 비교하기 위해 사용하는 상대적 예상 비용

[제출 결과]
- SELECT문
- EXPLAIN SQL
- EXPLAIN ANALYZE SQL
- 주요 실행계획 항목
- Q1~Q2 답변
*/

-- [코드 작성란]
--1번
select *
from orders
where order_id = 150000;

--2번
explain
select *
from orders
where order_id = 150000;

--3번
explain analyze
select *
from orders
where order_id = 150000;


/*
============================================================
필수 2. JOIN 실행계획 읽기
============================================================

[문제 2-1]

[문제 설명]
2023년에 발생한 주문과 고객 도시를 함께 조회하고,
JOIN 실행계획을 분석하세요.

[요구사항]
1. 다음 조건을 만족하는 SELECT문을 작성하세요.
   - orders.order_id 조회
   - orders.order_date 조회
   - orders.customer_id 조회
   - customers.city 조회
   - orders.customer_id = customers.customer_id로 JOIN
   - order_date >= DATE '2023-01-01'
   - order_date < DATE '2024-01-01'
2. 작성한 SELECT문에 EXPLAIN ANALYZE를 적용하세요.
3. 실행계획에서 다음 항목을 확인하세요.
   - orders의 스캔 방식: Seq Scan
   - customers의 스캔 방식: Seq Scan
   - 조인 방식: Hash Join
   - 주요 노드의 예상 rows: 50129
   - 주요 노드의 actual rows: 49853
4. 실행계획을 아래쪽 노드부터 위쪽 노드 방향으로 읽어
   데이터 처리 순서를 설명하세요.
5. Rows Removed by Filter가 표시된다면 의미를 설명하세요.
   - 조건이 맞지 않는 450147개의 행이 제외됨.
6. 다음 질문에 답하세요.
   Q1. JOIN 실행계획을 아래쪽 노드부터 읽는 이유는 무엇인가요?
   	- 상위 노드는 아래쪽 자식 노드의 결과를 입력으로 사용함.
   	- 데이터 처리 흐름을 이해하기 위해서 하위 노드부터 위쪽 노드를 따라가는 것이 좋음.
   	
   Q2. 예상 rows와 actual rows 차이가 크다면 무엇을 점검할 수 있나요?
   	- 옵티마이저의 행 수 추정이 실제 데이터 분포와 맞는지 점검해야 함.
   	
   Q3. orders와 customers의 Scan 노드에 표시된 actual rows와
       Rows Removed by Filter는 각각 무엇을 의미하나요?
    - actual rows: 실행 1회당 평균적으로 출력한 해수(loop = 1이면 그 노드의 총 출력 행 수)
    - Rows Removed by Filter: Scan 과정에서 확인했지만 필터 조건을 만족하지 않아 제외된 행 수

[제출 결과]
- SELECT문
- EXPLAIN ANALYZE SQL
- 테이블별 스캔 방식
- 조인 방식
- 처리 순서
- Rows Removed by Filter 해석
- Q1~Q3 답변
*/

-- [코드 작성란]
--1번
select 
	o.order_id,
	o.order_date,
	o.customer_id,
	c.city
from orders o 
join customers c
	on o.customer_id = c.customer_id
where o.order_date >= date '2023-01-01'
	and o.order_date < date '2024-01-01';

--2번
explain analyze
select 
	o.order_id,
	o.order_date,
	o.customer_id,
	c.city
from orders o 
join customers c
	on o.customer_id = c.customer_id
where o.order_date >= date '2023-01-01'
	and o.order_date < date '2024-01-01';


/*
============================================================
과제. order_items 실행계획 해석
============================================================

[문제 3-1]

[문제 설명]
order_items에서 product_id가 100인 주문상품을 조회하고,
EXPLAIN과 EXPLAIN ANALYZE를 이용해 실행계획을 직접 분석하세요.

※ 새로운 최적화 기법을 적용하는 문제가 아니라,
   필수 문제에서 배운 실행계획 읽기 방법을 반복 적용하는 문제입니다.

[요구사항]
1. order_items에서 product_id = 100인 행을 조회하세요.
2. 다음 컬럼을 출력하세요.
   - order_item_id
   - order_id
   - product_id
   - qty
   - price
3. 같은 SELECT문에 EXPLAIN을 적용하세요.
4. 같은 SELECT문에 EXPLAIN ANALYZE를 적용하세요.
5. 다음 항목을 확인해 기록하세요.
   - 스캔 방식 explain: Seq Scan / analyze: Seq Scan
   - cost의 시작 비용: 0.00
   - cost의 총 비용: 6947.00
   - 예상 rows: 25
   - actual rows: 16
   - Rows Removed by Filter: 199984
   - Execution Time: 145.358 ms
6. 예상 rows와 actual rows를 비교하여
   옵티마이저의 예상이 실제 결과와 어느 정도 일치하는지 설명하세요.
   - 예상 rows는 25건이고 actual rows는 16건으로 실제 결과와 9건 차이가 난다.
7. 다음 질문에 답하세요.
   Q1. 가장 먼저 확인해야 할 데이터 접근 방식은 무엇인가요?
   	- 테이블을 어떤 스캔 방식으로 읽는지 확인한다.(Seq Scan, Index Scan, Index Only Scan)
   Q2. Seq Scan은 테이블의 데이터를 어떤 방식으로 확인하나요?
	- 테이블의 데이터를 순차적으로 확인한다.
[제출 결과]
- SELECT문
- EXPLAIN SQL
- EXPLAIN ANALYZE SQL
- 주요 실행계획 항목
- 예상 rows와 actual rows 비교
- Q1~Q2 답변
*/

-- [코드 작성란]

--1번
select
	order_item_id,
    order_id,
    product_id,
    qty,
    price
from order_items
where product_id = 100;

--3번
explain
select
	order_item_id,
    order_id,
    product_id,
    qty,
    price
from order_items
where product_id = 100;

--4번
explain analyze
select
	order_item_id,
    order_id,
    product_id,
    qty,
    price
from order_items
where product_id = 100;


/*
============================================================
실습 마무리
============================================================

아래 질문에 답하세요.

1. EXPLAIN과 EXPLAIN ANALYZE의 가장 중요한 차이는 무엇인가요?
  - EXPLAIN은 옵티마이저의 예상 실행 계획은 보여 준다.
  - EXPLAIN ANALYZE는 쿼리를 실제 실행하여 Actual rows, actual time, Execution time 등 실제 실행 결과를 포함한다.
  
2. 스캔 방식과 처리 행 수를 함께 확인하면 무엇을 알 수 있나요?
  - 어떤 방식으로 각 테이블ㄹ에 접근했고 그 과정에서 몇 행을 예상하거나 실제로 처리했는지 파악 가능
   
3. JOIN 실행계획은 어떤 순서로 읽는 것이 좋나요?
  - 가장 아래쪽 Scan 노드부터 확인하고 상위 Join 노드까지 전달되는 방향으로 아래에서 위로 읽는다.
*/


