// A simple transaction to send to 2 components comp_a and comp_b 
import uvm_pkg::*;
`include "uvm_macros.svh"
program tb;

class transaction extends uvm_object;
  rand bit[3:0] data;
  rand bit[5:0] addr;
  rand bit wr_en;
  rand bit [2:0] id;
 
  
  `uvm_object_utils_begin(transaction);
  `uvm_field_int(data,UVM_ALL_ON)
  `uvm_field_int(addr,UVM_ALL_ON)
  `uvm_field_int(wr_en,UVM_ALL_ON)
  `uvm_field_int(id,UVM_ALL_ON)
  `uvm_object_utils_end;
  
  
  function new (string name  = "transaction");
    super.new(name);
  endfunction  
  
  function bit match(transaction atrans);
    return (id == atrans.id &&  wr_en == atrans.wr_en);
  endfunction
    
endclass

// comp_a has a analysis port which it sends transactions to comp_c
// you can  see the write function getting called.

class comp_a extends uvm_component;
  `uvm_component_utils (comp_a)
  
  uvm_analysis_port #(transaction) broadcast_port;
  
  function new (string name = "comp_a", uvm_component parent);
    super.new(name,parent);
  endfunction
  
   function void build_phase(uvm_phase phase);
     broadcast_port = new("broadcast_port",this);
  endfunction
  
  task run_phase (uvm_phase phase);
    transaction tx;
    
    
    
    repeat (5) begin
      tx = transaction::type_id::create("tx", this);
    void'(tx.randomize());
    `uvm_info(get_type_name(),$sformatf(" tranaction randomized"),UVM_LOW)
    tx.print();
    `uvm_info(get_type_name(),$sformatf(" tranaction sending to comp_c"),UVM_LOW)
    broadcast_port.write(tx);
    end
  endtask  
  
endclass

// comp_b has a analysis port which it sends transactions to comp_c
// you can see the write function getting called.
// Manually force the comp_b to send the transaction to comp_c (scoreboard in our case) out of order.  

class comp_b extends uvm_component;
  `uvm_component_utils (comp_b)
  
  uvm_analysis_port #(transaction) aport_send;
  
  function new (string name = "comp_b", uvm_component parent);
    super.new(name,parent);
  endfunction
  
   function void build_phase(uvm_phase phase);
     aport_send = new("aport_send",this);
  endfunction
  
  task run_phase (uvm_phase phase);
    transaction trans;
    
    
    
    
   // repeat (5) begin
      trans = transaction::type_id::create("trans", this);
    `uvm_info(get_type_name(),$sformatf(" tranaction  randomized"),UVM_LOW)
    void' (trans.randomize() with {trans.id==7;});
      trans.print();
    `uvm_info(get_type_name(),$sformatf(" tranaction sending to comp_c"),UVM_LOW)
     aport_send.write(trans);
    trans = transaction::type_id::create("trans", this);
     `uvm_info(get_type_name(),$sformatf(" tranaction  randomized"),UVM_LOW)
    void' (trans.randomize() with {trans.id==0;});
      trans.print();
    `uvm_info(get_type_name(),$sformatf(" tranaction sending to comp_c"),UVM_LOW)
    aport_send.write(trans);
    
    //end
  endtask  
 
endclass

// comp_c has two imp_decl ports which is called comp_a export and comp_b export
// comp_c also implements two write functions one for comp_a and one for comp_b
// comp_c is what we call scoreboard which receives two transactions one from comp_a and one from comp_b and then compares it.  

  `uvm_analysis_imp_decl(_comp_a)
  `uvm_analysis_imp_decl(_comp_b)
  
  class comp_c extends uvm_component;
    `uvm_component_utils (comp_c)
  
    uvm_analysis_imp_comp_a #(transaction,comp_c) comp_a_export;
    uvm_analysis_imp_comp_b #(transaction,comp_c) comp_b_export;
    
    // Associative array holding the transactions from two sources comp_a and comp_b indexed through id field.
    transaction dut_q[int];
    transaction ref_q[int];
    int match;
    int no_match;
   
    
    function new (string name = "comp_c", uvm_component parent);
    super.new(name,parent);
  endfunction
  
   function void build_phase(uvm_phase phase);
     comp_a_export = new ("comp_a_export",this);
     comp_b_export = new ("comp_b_export",this);
  endfunction
    
    // Assume comp_a has original transaction
  
    function void write_comp_a (transaction t);
      `uvm_info(get_type_name(),$sformatf(" tranaction Received in scoreboard from comp_a"),UVM_LOW)
       dut_q[t.id] = t;
       t.print();
    endfunction

    
    
    function void write_comp_b (transaction tr);
      `uvm_info(get_type_name(),$sformatf(" tranaction Received in scoreboard from comp_b"),UVM_LOW)
      ref_q[tr.id] = tr;
      tr.print();
    endfunction
    
    function void compare ();
      transaction dut_ty;
      transaction ref_tr;
      int id;
      bit match_tr;
      // Add a check
      // Iterate through all the transactions in the dut_q which is list of transactions received from comp_a 
      
      foreach (dut_q[i]) begin
        `uvm_info ("DUT",$sformatf ("ID : %d, Addr : %0d , Data : %0d, wr_en : %0d,",dut_q[i].id,dut_q[i].addr,dut_q[i].data,dut_q[i].wr_en),UVM_LOW);
       // Store the id in a variable 
        id = dut_q[i].id;
       // Check the variable id in the ref_q which is list of transactions received from comp_b in this case 
        if (ref_q.exists(id)) begin
          `uvm_info ("Match",$sformatf("Matching transaction found in ref_q with id = %d",id),UVM_LOW);
          // If you have a match, populated the transaction with the same ID from both the arrays and then do a match 
          dut_ty = dut_q[id];
          ref_tr = ref_q[id];
          `uvm_info ("In loop",$sformatf ("ID : %d, Addr : %0d , Data : %0d, wr_en : %0d,",dut_q[id].id,dut_q[id].addr,dut_q[id].data,dut_q[id].wr_en),UVM_LOW);
         // In this case, you will see three transactions matching the ID, but only one matches exactly.
          // The transaction has a compare function which compares two field one is ID and another one is wr_en
         // If both of them are equal, Bingo we found a match !!  
          if(dut_ty.match(ref_tr)) begin
            `uvm_info ("Equal",$sformatf("Transactions are equal = %d, ID : %d, wr_en %d",match_tr,dut_ty.id,dut_ty.wr_en),UVM_LOW);
          end
        end
       end
      // Iterate through all the transactions in the dut_q which is list of transactions received from comp_b
      foreach (ref_q[i])
        `uvm_info ("REF",$sformatf ("ID : %d, Addr : %0d , Data : %0d, wr_en : %0d,",ref_q[i].id,ref_q[i].addr,ref_q[i].data,ref_q[i].wr_en),UVM_LOW);
      
   endfunction
      
      
   
 
    function void check_phase(uvm_phase phase);
    super.check_phase(phase);
    compare();
    REF_Q : assert(ref_q.size() == 0) else
      `uvm_error("COMPARATOR_REF_Q_NOT_EMPTY_ERR", $sformatf("ref_q is not empty!!! It still contains %d transactions!", ref_q.size()))
       
    DUT_Q : assert(dut_q.size() == 0) else
      `uvm_error("COMPARATOR_DUT_Q_NOT_EMPTY_ERR", $sformatf("dut_q is not empty!!! It still contains %d transactions!", dut_q.size()))
     
  endfunction
    
endclass

// Top env connects comp_a export to comp_c imp port.
// Top env connects comp_b export to comp_c imp port.

class my_env extends uvm_env;
  `uvm_component_utils(my_env)
  
  comp_a test_a;
  comp_b test_b;
  comp_c test_c;
  
  function new (string name = "my_env", uvm_component parent=null);
    super.new(name,parent);
  endfunction
  
   function void build_phase(uvm_phase phase);
     test_a = comp_a::type_id::create("test_a",this);
     test_b = comp_b::type_id::create("test_b",this);
     test_c = comp_c::type_id::create("test_c",this);
  endfunction
  
  function void connect_phase(uvm_phase phase);
    test_a.broadcast_port.connect(test_c.comp_a_export);
    test_b.aport_send.connect(test_c.comp_b_export);
    
  endfunction
  
endclass

class base_test extends uvm_test;

  `uvm_component_utils(base_test)
  
 
  my_env env;

  
  function new(string name = "base_test",uvm_component parent=null);
    super.new(name,parent);
  endfunction : new

 
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    env = my_env::type_id::create("env", this);
  endfunction : build_phase
  
  
   function void end_of_elaboration();
   
    print();
  endfunction
  
  virtual task run_phase(uvm_phase phase);
    phase.raise_objection(this);
    #500;
    phase.drop_objection(this);
  endtask
  
endclass : base_test



  initial begin
    run_test("base_test");  
  end  
  
endprogram
