
//halfway between unsynchronized and synchronized
//doesn't use synchronized code, but uses volatile access 
//to array elements

import java.util.concurrent.atomic.AtomicIntegerArray;

class GetNSet implements State {
    private AtomicIntegerArray value;
    private byte maxval;

    private int[] byte_arr_to_int(byte[] v) {
        int[] int_arr = new int[v.length];
        for (int i = 0; i < v.length; i++){
            int_arr[i] = v[i];
        }
        return int_arr;
    }

    private byte[] atom_to_byte(AtomicIntegerArray v) {
        byte[] byte_arr= new byte[v.length()];
        for (int i = 0; i < v.length(); i++) {
            byte_arr[i] = (byte) v.get(i); // need to cast because downcasting, make sure each element not stored in too large blocks
        }
        return byte_arr;
    }

    GetNSet(byte[] v) {
        int[] intArray = byte_arr_to_int(v);
        this.value = new AtomicIntegerArray(intArray);
        this.maxval = 127;
    }

    GetNSet(byte[] v, byte maxval) {
        int[] int_arr = byte_arr_to_int(v);
        this.value = new AtomicIntegerArray(int_arr);
        this.maxval = maxval;
    }

    public int size() { return value.length(); }

    public byte[] current() { return atom_to_byte(this.value); }

    public boolean swap(int i, int j) {
//	System.out.println("running"); 
        int i_prev = value.get(i);
       int prev_j = value.get(j);
        if (value.get(i)<= 0 || value.get(j)>= maxval) {
            return false;
        }

        value.set(i, i_prev - 1);
        value.set(j, prev_j + 1);
        return true;
    }
}


