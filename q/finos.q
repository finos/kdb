//system"l ",1_string .Q.rp`:.:finos_init.q;
system"l ",1_string .Q.rp`:::../finos_init.q;

provide:{[x;a]
    if[not (sm:string[x]) in key .finos.dep.list;'"module not registered: ",.Q.s1 x];
    n:` sv .z.M,`m,x;
    path:.finos.dep.list[sm;`scriptPath];
    l:.Q.m.p1 ll:.Q.m.pl[enlist path;enlist x];
    if[0=count l;
        -2 each enlist["tried the following paths:"],"  ",/:ll;
        '"notfound: ",string x];
    if[not null m:.Q.m.M[(p:.Q.m.dl l;`)]`m;
        $[m~`:;'`cycle;:m]];
    r:.Q.m.ch[n;p;`;.Q.m.ld l;a];
    :[r;(0b;r);
            [.Q.m.M[(p;`)]:enlist[`m]!enlist n;n];
        (1b;r);
            'r]}

export:([provide])
