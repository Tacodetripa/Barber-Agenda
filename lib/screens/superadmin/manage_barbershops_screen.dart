import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/barbershop_provider.dart';
import '../../providers/auth_provider.dart';
import 'create_barbershop_screen.dart';
import 'edit_barbershop_screen.dart';

class ManageBarbershopsScreen extends StatefulWidget {
  const ManageBarbershopsScreen({super.key});

  @override
  State<ManageBarbershopsScreen> createState() => _ManageBarbershopsScreenState();
}

class _ManageBarbershopsScreenState extends State<ManageBarbershopsScreen> {
  @override
  void initState() {
    super.initState();
    // Cargar barberías
    context.read<BarbershopProvider>().loadBarbershops();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestionar Barberías'),
      ),
      body: Consumer<BarbershopProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.barbershops.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.store_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No hay barberías registradas',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Crea la primera barbería',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.barbershops.length,
            itemBuilder: (context, index) {
              final barbershop = provider.barbershops[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                    child: Icon(
                      Icons.store,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  title: Text(barbershop.name),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(barbershop.address),
                      const SizedBox(height: 4),
                      Text(
                        '${barbershop.openingTime} - ${barbershop.closingTime}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  trailing: PopupMenuButton(
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 20),
                            SizedBox(width: 8),
                            Text('Editar'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 20, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Eliminar', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                      onSelected: (value) async {
                        if (value == 'edit') {
                          // 🆕 EDITAR BARBERÍA
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EditBarbershopScreen(
                                barbershop: barbershop,
                              ),
                            ),
                          );
                          // Recargar lista
                          provider.loadBarbershops();
                        } else if (value == 'delete') {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Eliminar Barbería'),
                              content: Text(
                                '¿Estás seguro de eliminar "${barbershop.name}"?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  child: const Text('Cancelar'),
                                ),
                                FilledButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: Colors.red,
                                  ),
                                  child: const Text('Eliminar'),
                                ),
                              ],
                            ),
                          );

                          if (confirm == true && mounted) {
                            final success = await provider.deleteBarbershop(barbershop.id);

                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    success
                                        ? '${barbershop.name} eliminada exitosamente'
                                        : 'Error al eliminar barbería',
                                  ),
                                  backgroundColor: success ? Colors.green : Colors.red,
                                  duration: const Duration(seconds: 3),
                                ),
                              );

                              // Recargar lista si fue exitoso
                              if (success) {
                                provider.loadBarbershops();
                              }
                            }
                          }
                        }
                      },
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CreateBarbershopScreen(),
            ),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Nueva Barbería'),
      ),
    );
  }
}