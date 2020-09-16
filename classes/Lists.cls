public with sharing class Lists {

    public static List<List<Object>> doPartions(List<sObject> records, Integer size){
        checkNotNull(records);
        checkArgument(size > 0);
        return new Partition(records, size).doPartition();
    }

    private static void checkNotNull(Object reference) {
        if (reference == null) {
            throw new NullPointerException();
        }
    }

    private static void checkArgument(Boolean expression) {
        if (!expression) {
            throw new IllegalArgumentException();
        }
    }

    private class Partition{
        private List<sObject> items;
        private Integer splitSize;

        Partition(List<sObject> records, Integer size){
            this.items = records;
            this.splitSize = size;
        }

        List<List<sObject>> doPartition(){
            List<List<sObject>> result = new List<List<sObject>>();
            List<sObject> protoList = items.clone();
            protoList.clear();
            List<sObject> tempList = protoList.clone();
            Integer index = 0, count = 0, size = items.size();
            while(index < size) {
                tempList.add(items.get(index++));
                ++count;
                if(count == splitSize) {
                    result.add(tempList);
                    tempList = protoList.clone();
                    count = 0;
                }
            }
            if(!tempList.isEmpty()) {
                result.add(tempList);
            }
            return result;
        }
    }

    public class IllegalArgumentException extends Exception {}
}