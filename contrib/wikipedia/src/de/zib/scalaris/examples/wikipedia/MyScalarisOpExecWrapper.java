package de.zib.scalaris.examples.wikipedia;

import de.zib.scalaris.examples.wikipedia.ScalarisDataHandler.ScalarisOpType;
import de.zib.scalaris.executor.ScalarisIncrementOp1;
import de.zib.scalaris.executor.ScalarisIncrementOp2;
import de.zib.scalaris.executor.ScalarisOpExecutor;
import de.zib.scalaris.executor.ScalarisWriteOp;

/**
 * Wraps {@link ScalarisOpExecutor} and adds the different operations
 * based on the current configuration.
 * 
 * @author Nico Kruber, kruber@zib.de
 */
public class MyScalarisOpExecWrapper {
    protected final ScalarisOpExecutor executor;
    /**
     * Creates a new wrapper with the given executor.
     * 
     * @param executor the executor to use.
     */
    public MyScalarisOpExecWrapper(MyScalarisTxOpExecutor executor) {
        this.executor = executor;
    }

    /**
     * Creates a new write operation.
     * 
     * @param opType    the type of the operation
     * @param key       the key to write the value to
     * @param value     the value to write
     * 
     * @param <T>       type of the value
     */
    public <T> void addWrite(ScalarisOpType opType, String key, T value) {
        switch (opType) {
        default:
            executor.addOp(new ScalarisWriteOp<T>(key, value));
        }
    }

    /**
     * Creates a new list append operation.
     * 
     * @param opType    the type of the operation
     * @param key       the key to append the value to
     * @param toAdd     the value to add
     * @param countKey  the key for the counter of the entries in the list
     *                  (may be <tt>null</tt>)
     * 
     * @param <T>       type of the value to add
     */
    public <T> void addAppend(ScalarisOpType opType, String key, T toAdd, String countKey) {
        switch (opType) {
        default:
            if (Options.WIKI_USE_NEW_SCALARIS_OPS) {
                executor.addOp(new ScalarisListAppendOp2<T>(key, toAdd, countKey));
            } else {
                executor.addOp(new ScalarisListAppendOp1<T>(key, toAdd, countKey));
            }
        }
    }

    /**
     * Creates a new list remove operation.
     * 
     * @param opType    the type of the operation
     * @param key       the key to remove the value from
     * @param toRemove  the value to remove
     * @param countKey  the key for the counter of the entries in the list
     *                  (may be <tt>null</tt>)
     * 
     * @param <T>       type of the value to remove
     */
    public <T> void addRemove(ScalarisOpType opType, String key, T toRemove, String countKey) {
        switch (opType) {
        default:
            if (Options.WIKI_USE_NEW_SCALARIS_OPS) {
                executor.addOp(new ScalarisListRemoveOp2<T>(key, toRemove, countKey));
            } else {
                executor.addOp(new ScalarisListRemoveOp1<T>(key, toRemove, countKey));
            }
        }
    }

    /**
     * Creates a new number increment operation.
     * 
     * @param opType    the type of the operation
     * @param key       the key of the value to increment
     * @param toAdd     the value to increment by
     * 
     * @param <T>       type of the value to add
     */
    public <T extends Number> void addIncrement(ScalarisOpType opType, String key, T toAdd) {
        switch (opType) {
        default:
            if (Options.WIKI_USE_NEW_SCALARIS_OPS) {
                executor.addOp(new ScalarisIncrementOp2<T>(key, toAdd));
            } else {
                executor.addOp(new ScalarisIncrementOp1<T>(key, toAdd));
            }
        }
    }

    /**
     * @return the executor
     */
    public ScalarisOpExecutor getExecutor() {
        return executor;
    }
}