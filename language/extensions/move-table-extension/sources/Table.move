/// Type of large-scale storage tables.
module Extensions::Table {
    use Std::Errors;

    // native code raises this with Errors::invalid_arguments()
    const EALREADY_EXISTS: u64 = 100;
    // native code raises this with Errors::invalid_arguments()
    const ENOT_FOUND: u64 = 101;
    const ENOT_EMPTY: u64 = 102;

    /// Type of tables
    struct Table<phantom K, phantom V> has store {
        handle: u128,
        length: u64,
    }

    /// Create a new Table.
    public fun new<K, V: store>(): Table<K, V> {
        Table{
            handle: new_table_handle(),
            length: 0,
        }
    }

    /// Destroy a table. The table must be empty to succeed.
    public fun destroy_empty<K, V>(table: Table<K, V>) {
        assert!(table.length == 0, Errors::invalid_state(ENOT_EMPTY));
        destroy_empty_box<K, V, Box<V>>(&table);
        drop_unchecked_box<K, V, Box<V>>(table)
    }

    /// Add a new entry to the table. Aborts if an entry for this
    /// key already exists. The entry itself is not stored in the
    /// table, and cannot be discovered from it.
    public fun add<K, V>(table: &mut Table<K, V>, key: &K, val: V) {
        add_box<K, V, Box<V>>(table, key, Box{val});
        table.length = table.length + 1
    }

    /// Acquire an immutable reference to the value which `key` maps to.
    /// Aborts if there is no entry for `key`.
    public fun borrow<K, V>(table: &Table<K, V>, key: &K): &V {
        &borrow_box<K, V, Box<V>>(table, key).val
    }

    /// Acquire a mutable reference to the value which `key` maps to.
    /// Aborts if there is no entry for `key`.
    public fun borrow_mut<K, V>(table: &mut Table<K, V>, key: &K): &mut V {
        &mut borrow_box_mut<K, V, Box<V>>(table, key).val
    }

    /// Returns the length of the table, i.e. the number of entries.
    public fun length<K, V>(table: &Table<K, V>): u64 {
        table.length
    }

    /// Returns true if this table is empty.
    public fun empty<K, V>(table: &Table<K, V>): bool {
        table.length == 0
    }

    /// Acquire a mutable reference to the value which `key` maps to.
    /// Insert the pair (`key`, `default`) first if there is no entry for `key`.
    public fun borrow_mut_with_default<K, V: drop>(table: &mut Table<K, V>, key: &K, default: V): &mut V {
        if (!contains(table, key)) {
            add(table, key, default)
        };
        borrow_mut(table, key)
    }

    /// Remove from `table` and return the value which `key` maps to.
    /// Aborts if there is no entry for `key`.
    public fun remove<K, V>(table: &mut Table<K, V>, key: &K): V {
        let Box{val} = remove_box<K, V, Box<V>>(table, key);
        table.length = table.length - 1;
        val
    }

    /// Returns true iff `table` contains an entry for `key`.
    public fun contains<K, V>(table: &Table<K, V>, key: &K): bool {
        contains_box<K, V, Box<V>>(table, key)
    }

    #[test_only]
    /// Testing only: allows to drop a table even if it is not empty.
    public fun drop_unchecked<K, V>(table: Table<K, V>) {
        drop_unchecked_box<K, V, Box<V>>(table)
    }

    // ======================================================================================================
    // Internal API

    /// Wrapper for values. Required for making values appear as resources in the implementation.
    struct Box<V> has key, drop, store {
        val: V
    }

    // Primitives which take as an additional type parameter `Box<V>`, so the implementation
    // can use this to determine serialization layout.
    native fun new_table_handle(): u128;
    native fun add_box<K, V, B>(table: &mut Table<K, V>, key: &K, val: Box<V>);
    native fun borrow_box<K, V, B>(table: &Table<K, V>, key: &K): &Box<V>;
    native fun borrow_box_mut<K, V, B>(table: &mut Table<K, V>, key: &K): &mut Box<V>;
    native fun contains_box<K, V, B>(table: &Table<K, V>, key: &K): bool;
    native fun remove_box<K, V, B>(table: &mut Table<K, V>, key: &K): Box<V>;
    native fun destroy_empty_box<K, V, B>(table: &Table<K, V>);
    native fun drop_unchecked_box<K, V, B>(table: Table<K, V>);
}
