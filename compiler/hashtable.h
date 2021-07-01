#ifndef HASH_TABLE_H
#define HASH_TABLE_H

static inline long PTR_ERR(const void *ptr)
{
	return (long) ptr;
}

static inline void *ERR_PTR(long err)
{
	return (void *) err;
}

struct hash_slot {
	char *key;  
	unsigned long value;
	struct hash_slot *next;
};

struct hash_table {
	unsigned long size;
	struct hash_slot **table;
};

struct hash_table *ht_create(unsigned long );
int ht_insert(struct hash_table *, char *, int );
unsigned int ht_get(struct hash_table *, char *);
#endif
