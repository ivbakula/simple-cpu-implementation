#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <limits.h>
#include <errno.h>

#include "hashtable.h"

#define GETTER 0
#define SETTER 1

struct hash_table *ht_create(unsigned long size)
{
	struct hash_table *ht = NULL;

	ht = (struct hash_table *) malloc(sizeof(*ht));
	if (!ht)
		return NULL;

	ht->table = calloc(sizeof(*ht->table), size);
	if (!ht->table)
		return NULL;

	ht->size = size;
	return ht;
}

static unsigned long ht_get_hash(unsigned long ht_size, char *key)
{
	unsigned long hash = 0; 
	int key_size = strlen(key);
	for(int i = 0; i < key_size && hash < ULONG_MAX; i++) {
		hash = hash << 4;
		hash += key[i];
	}

	return hash % ht_size;
}

static struct hash_slot *ht_create_slot(char *key, unsigned long value)
{			
	struct hash_slot *slt = malloc(sizeof(*slt));
	if (!slt)
		return NULL;

	slt->key = strdup(key);
	slt->value = value;

	return slt;
}

/* type = GETTER || SETTER */
struct hash_slot *ht_probe(struct hash_table *ht, char *key, unsigned long index, int type)
{		
	struct hash_slot *head = NULL;
	struct hash_slot *tail = NULL;
	if (!ht->table[index]) 
		return ERR_PTR(-ENOENT);

	head = ht->table[index];
	while(head && head->key != NULL && strcmp(key, head->key)) {
		tail = head;
		head = head->next;	
	}

	if (!head) {
		if (type == SETTER)
			return tail; 
		else
			return ERR_PTR(-ENOENT);
	}

	if (type == SETTER)
		return ERR_PTR(-EEXIST);
	else
		return head;
}

int ht_insert(struct hash_table *ht, char *key, int value)
{
	unsigned long hash = ht_get_hash(ht->size, key);
	struct hash_slot *slt = ht_probe(ht, key, hash, SETTER);

	switch(PTR_ERR(slt)) {
		case -EEXIST: return -EEXIST; break;
		case -ENOENT: ht->table[hash] = ht_create_slot(key, value); return 0;
		default: slt->next = ht_create_slot(key, value); return 0;
	}
}


unsigned int ht_get(struct hash_table *ht, char *key)
{
	unsigned long hash = ht_get_hash(ht->size, key);
	struct hash_slot *slt = ht_probe(ht, key, hash, GETTER);

	if (PTR_ERR(slt) == -ENOENT)
		return -ENOENT;

	return slt->value;
}
