TARGET = parser
OBJECT = lex.yy.c y.tab.c
CC     = gcc
CFLAGS = -Wall -Wextra -pedantic -g3
LEX    = flex
parser = yacc
LIBS   = -lfl

all: $(TARGET)

$(TARGET): lex.yy.c y.tab.c
	$(CC) lex.yy.c y.tab.c -ly -o $(TARGET) $(LIBS)
	
lex.yy.c: lex.l
	$(LEX) $<

y.tab.c: parser.y
	$(parser) -d -v $<
	
.PHONY: clean

clean:
	$(RM) -f $(TARGET) $(OBJECT)
