
fun main(args: Array<String>) 
{
	val myList = listOf(1,2,3,4,5,6,7,8,9,10,11,12)

	val expected  = listOf(3,6,9,12)	
	val result = everyNth(myList, 3)

	val expected2 = listOf<Unit>()  
	val result2 = everyNth(expected2, 2) 
	assert(expected == result) 
	assert(expected2 == result2) 
	println("Passed testing") 
}

fun<T>everyNth(l: List<T>, n: Int):List<T> {
	if(n <= 0){ 
		throw Exception("Supplied n less than 0, please supply an n greater than 0") 	
	} 
	val new_list = l.filterIndexed{index, _ -> (index+1) % n == 0}
	return new_list 
}
