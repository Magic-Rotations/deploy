import tkinter as tk
from tkinter import ttk, filedialog, messagebox
import os
import shutil
from datetime import datetime

class SimpleBindPadManager:
    def __init__(self):
        # Create main window
        self.window = tk.Tk()
        self.window.title("Simple BindPad Manager")
        self.window.geometry("400x300")
        
        # Create main frame with padding
        main = ttk.Frame(self.window, padding="10")
        main.pack(fill=tk.BOTH, expand=True)
        
        # WoW Path
        path_label = ttk.Label(main, text="WoW Installation Path:")
        path_label.pack(anchor=tk.W)
        
        path_frame = ttk.Frame(main)
        path_frame.pack(fill=tk.X, pady=(0, 10))
        
        self.path_var = tk.StringVar()
        path_entry = ttk.Entry(path_frame, textvariable=self.path_var)
        path_entry.pack(side=tk.LEFT, fill=tk.X, expand=True, padx=(0, 5))
        
        browse_btn = ttk.Button(path_frame, text="Browse", command=self.browse_path)
        browse_btn.pack(side=tk.RIGHT)
        
        # Account Name
        ttk.Label(main, text="WoW Account Name:").pack(anchor=tk.W)
        self.account_var = tk.StringVar()
        ttk.Entry(main, textvariable=self.account_var).pack(fill=tk.X, pady=(0, 10))
        
        # Character Name
        ttk.Label(main, text="Character Name:").pack(anchor=tk.W)
        self.char_var = tk.StringVar()
        ttk.Entry(main, textvariable=self.char_var).pack(fill=tk.X, pady=(0, 10))
        
        # Status
        self.status_var = tk.StringVar(value="Ready")
        status = ttk.Label(main, textvariable=self.status_var, wraplength=380)
        status.pack(fill=tk.X, pady=10)
        
        # Buttons
        btn_frame = ttk.Frame(main)
        btn_frame.pack(pady=10)
        
        ttk.Button(btn_frame, text="Create Backup", command=self.create_backup).pack(side=tk.LEFT, padx=5)
        ttk.Button(btn_frame, text="Import Bindings", command=self.import_bindings).pack(side=tk.LEFT, padx=5)

    def set_status(self, message):
        timestamp = datetime.now().strftime("%H:%M:%S")
        self.status_var.set(f"[{timestamp}] {message}")
        self.window.update()

    def browse_path(self):
        path = filedialog.askdirectory(title="Select WoW Installation Directory")
        if path:
            self.path_var.set(path)
            self.set_status("WoW path updated")

    def create_backup(self):
        try:
            wow_path = self.path_var.get()
            account = self.account_var.get()
            
            if not wow_path or not account:
                messagebox.showerror("Error", "Please fill in WoW path and account name")
                return
                
            bindpad_path = os.path.join(wow_path, "WTF", "Account", account, "SavedVariables", "BindPad.lua")
            
            if not os.path.exists(bindpad_path):
                messagebox.showerror("Error", "BindPad.lua not found")
                return
                
            backup_path = bindpad_path + f".bak.{datetime.now().strftime('%Y%m%d_%H%M%S')}"
            shutil.copy2(bindpad_path, backup_path)
            
            self.set_status(f"Backup created: {os.path.basename(backup_path)}")
            messagebox.showinfo("Success", "Backup created successfully")
            
        except Exception as e:
            self.set_status(f"Error: {str(e)}")
            messagebox.showerror("Error", str(e))

    def import_bindings(self):
        try:
            wow_path = self.path_var.get()
            account = self.account_var.get()
            
            if not wow_path or not account:
                messagebox.showerror("Error", "Please fill in WoW path and account name")
                return
                
            # Get the import file
            import_file = filedialog.askopenfilename(
                title="Select Bindings File",
                filetypes=[("Lua files", "*.lua"), ("All files", "*.*")]
            )
            
            if not import_file:
                return
                
            # Target path
            bindpad_path = os.path.join(wow_path, "WTF", "Account", account, "SavedVariables", "BindPad.lua")
            
            # Create backup first
            backup_path = bindpad_path + f".bak.{datetime.now().strftime('%Y%m%d_%H%M%S')}"
            if os.path.exists(bindpad_path):
                shutil.copy2(bindpad_path, backup_path)
                self.set_status("Created backup before import")
            
            # Copy the import file
            shutil.copy2(import_file, bindpad_path)
            self.set_status("Bindings imported successfully")
            messagebox.showinfo("Success", "Bindings imported successfully")
            
        except Exception as e:
            self.set_status(f"Error: {str(e)}")
            messagebox.showerror("Error", str(e))

    def run(self):
        self.window.mainloop()

if __name__ == "__main__":
    app = SimpleBindPadManager()
    app.run() 