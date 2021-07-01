LL = lex
YY = yacc -d
CC = gcc

LEX=lex.yy.c
PARSER=y.tab.c y.tab.h

all: $(LEX) $(PARSER)
	$(CC) -ggdb lex.yy.c y.tab.c hashtable.c -o as 


$(LEX): assembler.l
	$(LL) assembler.l

$(PARSER): assembler.y
	$(YY) assembler.y

clean:
	rm as $(PARSER) $(LEX)

